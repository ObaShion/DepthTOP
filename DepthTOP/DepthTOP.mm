//
//  DepthTOP.mm
//  DepthTOP
//
//  Created by 大場史温 on 2026/02/16.
//

#import "DepthTOP.h"
#import <Foundation/Foundation.h>
#import <CoreML/CoreML.h>
#import <Vision/Vision.h>

// MLModel
#import "DepthAnythingV2SmallF16.h"

DepthTOP::DepthTOP(const TD::OP_NodeInfo* info)
{
    myContext = (TOP_Context*)info->context;
    mModel = nullptr;
    mRequest = nullptr;
    
    // MLの読み込み
    NSError *error = nil;
    DepthAnythingV2SmallF16 *mlModel = [[DepthAnythingV2SmallF16 alloc] initWithConfiguration:[[MLModelConfiguration alloc] init] error:&error];
    
    if (error != nil) {
        printf("Error: モデル読み込み失敗");
        return;
    }
    
    // visionフレームワーク用に変換
    VNCoreMLModel *visionModel = [VNCoreMLModel modelForMLModel:mlModel.model error:&error];
    
    VNCoreMLRequest *request = [[VNCoreMLRequest alloc] initWithModel:visionModel completionHandler:nil];
    
    request.imageCropAndScaleOption = VNImageCropAndScaleOptionScaleFill;
    
    mModel = (__bridge_retained void*)visionModel;
    mRequest = (__bridge_retained void*)request;
    
    printf("Success: モデル読み込み成功");
}

DepthTOP::~DepthTOP()
{
    if (mModel) CFRelease(mModel);
    if (mRequest) CFRelease(mRequest);
}

void DepthTOP::execute(TOP_Output *output, const OP_Inputs *inputs, void *reserved1)
{
    const OP_TOPInput* in = inputs->getInputTOP(0);
    if (!in) return;
    
    // GPUからTextureを持ってくる
    OP_TOPInputDownloadOptions opts;
    opts.pixelFormat = OP_PixelFormat::BGRA8Fixed;
    opts.verticalFlip = true;
    
    OP_SmartRef<OP_TOPDownloadResult> downloadResult = in->downloadTexture(opts, nullptr);
    
    if (!downloadResult) return;
    const void* inputData = downloadResult->getData();
    
    if (!inputData) return;
    
    int inWidth = in->textureDesc.width;
    int inHeight = in->textureDesc.height;
    
    // TD -> CVPixelBufferに変換
    CVPixelBufferRef pixelBuffer = NULL;
    
    CVReturn status = CVPixelBufferCreateWithBytes(kCFAllocatorDefault,
                                                   inWidth,
                                                   inHeight,
                                                   kCVPixelFormatType_32BGRA,
                                                   (void*)inputData,
                                                   inWidth * 4,
                                                   NULL,
                                                   NULL,
                                                   NULL,
                                                   &pixelBuffer);
    
    if (status != kCVReturnSuccess)
    {
        printf("Error: CVPixelBufferの作成失敗");
        return;
    }
    
    // 推論
    VNCoreMLRequest *request = (__bridge VNCoreMLRequest*)mRequest;
    VNImageRequestHandler *handler = [[VNImageRequestHandler alloc] initWithCVPixelBuffer:pixelBuffer options:@{}];
    
    NSError *error = nil;
    [handler performRequests:@[request] error:&error];
    
    CVPixelBufferRelease(pixelBuffer);
    
    if (error)
    {
        printf("Error:", error.localizedDescription.UTF8String);
        return;
    }
    
    id observation = request.results.firstObject;
    
    int outWidth = 0;
    int outHeight = 0;
    
    if ([observation isKindOfClass:[VNPixelBufferObservation class]])
    {
        VNPixelBufferObservation *pixelObs = (VNPixelBufferObservation *)observation;
        CVPixelBufferRef outBuffer = pixelObs.pixelBuffer;
        
        if (outBuffer)
        {
            CVPixelBufferLockBaseAddress(outBuffer, kCVPixelBufferLock_ReadOnly);
            outWidth = (int)CVPixelBufferGetWidth(outBuffer);
            outHeight = (int)CVPixelBufferGetHeight(outBuffer);
            
            uint64_t sizeBytes = outWidth * outHeight * 4 * sizeof(float);
            OP_SmartRef<TOP_Buffer> buf = myContext->createOutputBuffer(sizeBytes,
                                                                        TOP_BufferFlags::None,
                                                                        nullptr);
            float* mem = (float*)buf->data;
            
            OSType pixelFormat = CVPixelBufferGetPixelFormatType(outBuffer);
            void* baseAddress = CVPixelBufferGetBaseAddress(outBuffer);
            size_t bytesPerRow = CVPixelBufferGetBytesPerRow(outBuffer);
            
            if (mem && baseAddress) {
                for (int y = 0; y < outHeight; y++) {
                    uint8_t* rowPtr = (uint8_t*)baseAddress + y * bytesPerRow;
                    
                    for (int x = 0; x < outWidth; x++) {
                        float depthValue = 0.0f;
                        
                        if (pixelFormat == kCVPixelFormatType_OneComponent16Half)
                        {
                            // 16bit float
                            __fp16* valPtr = (__fp16*)rowPtr;
                            depthValue = (float)valPtr[x];
                        }
                        else if (pixelFormat == kCVPixelFormatType_OneComponent32Float) {
                            // 32bit float
                            float* valPtr = (float*)rowPtr;
                            depthValue = valPtr[x];
                        }
                        else {
                            depthValue = (float)((uint8_t*)rowPtr)[x * 4] / 255.0f;
                        }
                        
                        int outIndex = ((outHeight - 1 - y) * outWidth + x) * 4;
                        mem[outIndex + 0] = depthValue;
                        mem[outIndex + 1] = depthValue;
                        mem[outIndex + 2] = depthValue;
                        mem[outIndex + 3] = 1.0f;
                    }
                }
            }
            CVPixelBufferUnlockBaseAddress(outBuffer, kCVPixelBufferLock_ReadOnly);
            
            TOP_UploadInfo uploadInfo;
            uploadInfo.colorBufferIndex = 0;
            uploadInfo.bufferOffset = 0;
            uploadInfo.textureDesc.width = outWidth;
            uploadInfo.textureDesc.height = outHeight;
            uploadInfo.textureDesc.texDim = OP_TexDim::e2D;
            uploadInfo.textureDesc.pixelFormat = OP_PixelFormat::RGBA32Float;
            output->uploadBuffer(&buf, uploadInfo, nullptr);
            
            uint64_t colorSizeBytes = inWidth * inHeight * 4;
            OP_SmartRef<TOP_Buffer> colorBuf = myContext->createOutputBuffer(colorSizeBytes, TOP_BufferFlags::None, nullptr);
            
            if (colorBuf->data && inputData)
            {
                memcpy(colorBuf->data, inputData, colorSizeBytes);
            }
            
            TOP_UploadInfo colorUploadInfo;
            colorUploadInfo.colorBufferIndex = 1;
            colorUploadInfo.bufferOffset = 0;
            colorUploadInfo.textureDesc.width = inWidth;
            colorUploadInfo.textureDesc.height = inHeight;
            colorUploadInfo.textureDesc.texDim = OP_TexDim::e2D;
            colorUploadInfo.textureDesc.pixelFormat = OP_PixelFormat::BGRA8Fixed;
            
            colorUploadInfo.firstPixel = TOP_FirstPixel::TopLeft;
            
            output->uploadBuffer(&colorBuf, colorUploadInfo, nullptr);
            
            return;
        }
    }
    
    printf("Error:", [[observation className] UTF8String]);
}
