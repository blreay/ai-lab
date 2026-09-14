#!/usr/bin/env python3
import argparse
import statistics
import time

from openai import OpenAI


def benchmark_once(client, model, prompt, max_tokens, temperature):
    start_time = time.perf_counter()
    first_token_time = None
    output_parts = []

    stream = client.chat.completions.create(
        model=model,
        messages=[
            {"role": "user", "content": prompt}
        ],
        max_tokens=max_tokens,
        temperature=temperature,
        stream=True,
        stream_options={"include_usage": True},
    )

    usage = None

    for chunk in stream:
        now = time.perf_counter()

        if getattr(chunk, "usage", None):
            usage = chunk.usage

        if not chunk.choices:
            continue

        content = chunk.choices[0].delta.content
        if content:
            if first_token_time is None:
                first_token_time = now
            output_parts.append(content)

    end_time = time.perf_counter()
    output_text = "".join(output_parts)

    total_time = end_time - start_time
    ttft = (
        first_token_time - start_time
        if first_token_time is not None
        else None
    )
    generation_time = (
        end_time - first_token_time
        if first_token_time is not None
        else None
    )

    completion_tokens = (
        usage.completion_tokens
        if usage is not None
        else None
    )

    tokens_per_second = (
        completion_tokens / generation_time
        if completion_tokens is not None
        and generation_time is not None
        and generation_time > 0
        else None
    )

    return {
        "ttft": ttft,
        "total_time": total_time,
        "generation_time": generation_time,
        "completion_tokens": completion_tokens,
        "tokens_per_second": tokens_per_second,
        "output": output_text,
    }


def mean_or_none(values):
    values = [v for v in values if v is not None]
    return statistics.mean(values) if values else None


def format_number(value, unit=""):
    if value is None:
        return "N/A"
    return f"{value:.3f}{unit}"


def main():
    parser = argparse.ArgumentParser(
        description="测试兼容 OpenAI API 的大模型流式输出速度"
    )
    parser.add_argument(
        "--base-url",
        default="https://api.openai.com/v1",
        help="API Base URL",
    )
    parser.add_argument(
        "--api-key",
        required=True,
        help="API Key",
    )
    parser.add_argument(
        "--model",
        required=True,
        help="模型名称",
    )
    parser.add_argument(
        "--prompt",
        default="请详细介绍一下人工智能的发展历史。",
        help="测试提示词",
    )
    parser.add_argument(
        "--max-tokens",
        type=int,
        default=512,
        help="最大输出 Token 数",
    )
    parser.add_argument(
        "--temperature",
        type=float,
        default=0.0,
        help="采样温度",
    )
    parser.add_argument(
        "--runs",
        type=int,
        default=3,
        help="测试次数",
    )
    parser.add_argument(
        "--show-output",
        action="store_true",
        help="显示模型输出",
    )
    args = parser.parse_args()

    client = OpenAI(
        api_key=args.api_key,
        base_url=args.base_url,
    )

    results = []

    for i in range(args.runs):
        print(f"\n===== 第 {i + 1}/{args.runs} 次测试 =====")

        try:
            result = benchmark_once(
                client=client,
                model=args.model,
                prompt=args.prompt,
                max_tokens=args.max_tokens,
                temperature=args.temperature,
            )
            results.append(result)

            print(f"首 Token 延迟: {format_number(result['ttft'], ' 秒')}")
            print(f"生成阶段耗时: {format_number(result['generation_time'], ' 秒')}")
            print(f"请求总耗时:   {format_number(result['total_time'], ' 秒')}")
            print(f"输出 Token:   {result['completion_tokens'] or 'N/A'}")
            print(
                f"输出速度:      "
                f"{format_number(result['tokens_per_second'], ' tokens/s')}"
            )

            if args.show_output:
                print("\n模型输出：")
                print(result["output"])

        except Exception as exc:
            print(f"请求失败: {exc}")

    if not results:
        print("\n没有成功完成的测试。")
        return

    print("\n===== 汇总 =====")
    print(
        "平均首 Token 延迟: "
        f"{format_number(mean_or_none([r['ttft'] for r in results]), ' 秒')}"
    )
    print(
        "平均请求总耗时:   "
        f"{format_number(mean_or_none([r['total_time'] for r in results]), ' 秒')}"
    )
    print(
        "平均生成速度:     "
        f"{format_number(mean_or_none([r['tokens_per_second'] for r in results]), ' tokens/s')}"
    )


if __name__ == "__main__":
    main()
