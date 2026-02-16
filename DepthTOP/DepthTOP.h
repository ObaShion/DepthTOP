//
//  DepthTOP.h
//  DepthTOP
//
//  Created by 大場史温 on 2026/02/16.
//

#pragma once

#include "TOP_CPlusPlusBase.h"
using namespace TD;

class DepthTOP : public TOP_CPlusPlusBase {
public:
    DepthTOP(const OP_NodeInfo* info);
    virtual ~DepthTOP();
    
    virtual void execute(TOP_Output* output,
                         const OP_Inputs* inputs,
                         void* reserved1) override;
    
    virtual void getGeneralInfo(TOP_GeneralInfo* ginfo,
                                const OP_Inputs* inputs,
                                void* reserved1) override;
    
    virtual bool getOutputFormat(TOP_OutputFormat* format,
                                 const OP_Inputs* inputs,
                                 TOP_Context* context,
                                 int outputIndex);

private:
    TOP_Context* myContext; // TDのコンテキスト
    
    void* mModel; // CoreMLモデル
    void* mRequest;
};
