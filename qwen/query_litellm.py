#!/usr/bin/env python3
"""
Qwen模型推理能力检测脚本
"""
import requests
import json
from typing import Dict, List

def check_model_capabilities(base_url: str = "http://localhost:4000"):
    """检查模型的推理能力"""
    
    print("=" * 60)
    print("🔍 检测 Qwen 模型推理能力")
    print("=" * 60)
    
    # 1. 获取模型列表
    print("\n📋 1. 获取可用模型:")
    try:
        response = requests.get(f"{base_url}/v1/models")
        if response.status_code == 200:
            models = response.json()
            for model in models.get("data", []):
                print(f"  - 模型ID: {model['id']}")
                print(f"    所有者: {model.get('owned_by', 'unknown')}")
                if "qwen" in model['id'].lower():
                    print(f"    ⚡ 这是Qwen模型")
    except Exception as e:
        print(f"  ❌ 获取模型列表失败: {e}")
    
    # 2. 测试不同的推理级别
    print("\n🧪 2. 测试推理级别:")
    test_levels = [
        {"level": "low", "description": "低推理强度"},
        {"level": "medium", "description": "中等推理强度"},
        {"level": "high", "description": "高推理强度"},
        {"level": "xhigh", "description": "xhigh高推理强度"},
        {"level": "minimal", "description": "最小推理"},
        {"level": "auto", "description": "自动推理"},
        {"level": "off", "description": "关闭推理"},
    ]
    
    for test in test_levels:
        try:
            response = requests.post(
                f"{base_url}/v1/chat/completions",
                json={
                    "model": "qwen-local",
                    "messages": [
                        {"role": "user", "content": "1+1等于几？"}
                    ],
                    "max_tokens": 50,
                    "reasoning_effort": test["level"]
                },
                timeout=30
            )
            
            if response.status_code == 200:
                result = response.json()
                message = result['choices'][0]['message']
                has_reasoning = 'reasoning_content' in message
                
                print(f"  ✅ {test['level']:10s} ({test['description']})")
                print(f"     内容: {message['content'][:50]}...")
                print(f"     有推理过程: {has_reasoning}")
                if has_reasoning:
                    print(f"     推理内容: {message['reasoning_content'][:50]}...")
            else:
                print(f"  ❌ {test['level']:10s} - HTTP {response.status_code}")
                print(f"     错误: {response.json().get('error', {}).get('message', 'Unknown')}")
                
        except requests.exceptions.Timeout:
            print(f"  ⏱️ {test['level']:10s} - 请求超时")
        except Exception as e:
            print(f"  ❌ {test['level']:10s} - 错误: {str(e)}")
    
    # 3. 检查 thinking 功能
    print("\n🧠 3. 检查 thinking 功能:")
    try:
        response = requests.post(
            f"{base_url}/v1/chat/completions",
            json={
                "model": "qwen-local",
                "messages": [
                    {"role": "system", "content": "请用中文思考"},
                    {"role": "user", "content": "解释什么是AI"}
                ],
                "max_tokens": 100,
                "extra_body": {
                    "enable_thinking": True,
                    "reasoning_preserve": True,
                    "thinking_budget": 200
                }
            }
        )
        
        if response.status_code == 200:
            result = response.json()
            print(f"  ✅ Thinking 功能可用")
            print(f"  📝 响应字段: {list(result['choices'][0]['message'].keys())}")
        else:
            print(f"  ❌ Thinking 功能不可用")
            
    except Exception as e:
        print(f"  ❌ 检查失败: {e}")
    
    print("\n" + "=" * 60)
    print("✅ 检测完成")
    print("=" * 60)

if __name__ == "__main__":
    check_model_capabilities()
