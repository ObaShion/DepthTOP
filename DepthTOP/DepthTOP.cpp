//
//  DepthTOP.cpp
//  DepthTOP
//
//  Created by 大場史温 on 2026/02/16.
//

#include "DepthTOP.h"
#include <stdio.h>

//void DepthTOP::execute(TOP_Output *output, const OP_Inputs *inputs, void *reserved1)
//{
//    int width = 256;
//    int height = 256;
//    
//    if (inputs->getNumInputs() > 0) {
//        const OP_TOPInput* in = inputs->getInputTOP(0);
//        width = in->textureDesc.width;
//        height = in->textureDesc.height;
//    }
//    
//    // メモリサイズ計算
//    // 幅×高さ×RGBA×floatSize
//    uint64_t sizeBytes = width * height * 4 * sizeof(float);
//    
//    OP_SmartRef<TOP_Buffer> buf = myContext->createOutputBuffer(sizeBytes, TOP_BufferFlags::None, nullptr);
//    
//    float* mem = (float*)buf->data;
//    
//    if(mem)
//    {
//        for (int y = 0; y < height; y++) {
//            for (int x = 0; x < width; x ++) {
//                int index = (y * width + x) * 4;
//                
//                mem[index + 0] = 1.0f; // R
//                mem[index + 1] = 0.0f; // G
//                mem[index + 2] = 0.0f; // B
//                mem[index + 3] = 1.0f; // A
//            }
//        }
//    }
//    
//    TOP_UploadInfo uploadInfo;
//    uploadInfo.bufferOffset = 0;
//    uploadInfo.textureDesc.width = width;
//    uploadInfo.textureDesc.height = height;
//    uploadInfo.textureDesc.texDim = OP_TexDim::e2D;
//    uploadInfo.textureDesc.pixelFormat = OP_PixelFormat::RGBA32Float;
//    
//    output->uploadBuffer(&buf, uploadInfo, nullptr);
//}

void DepthTOP::getGeneralInfo(TD::TOP_GeneralInfo *ginfo, const TD::OP_Inputs *inputs, void*)
{
    ginfo->cookEveryFrame = true;
}


bool DepthTOP::getOutputFormat(TD::TOP_OutputFormat *format, const TD::OP_Inputs *inputs, TD::TOP_Context*, int outputIndex)
{
    return false;
}


extern "C"
{
    DLLEXPORT
    void FillTOPPluginInfo(TOP_PluginInfo *info)
    {
        info->apiVersion = TOPCPlusPlusAPIVersion;
        info->executeMode = TOP_ExecuteMode::CPUMem;
    }

    DLLEXPORT
    TOP_CPlusPlusBase* CreateTOPInstance(const OP_NodeInfo* info)
    {
        return new DepthTOP(info);
    }

    DLLEXPORT
    void DestroyTOPInstance(TOP_CPlusPlusBase* instance)
    {
        delete (DepthTOP*)instance;
    }
}
