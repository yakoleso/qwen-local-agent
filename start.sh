#!/bin/bash
set -e

echo "🚀 Starting llama.cpp server (Qwen2.5-0.5B-Q2_K)..."
cd llama.cpp

# Запуск сервера на 8080, CPU-only, минимум памяти
./server \
  -m ../model.gguf \
  -p 8080 \
  --threads 4 \
  --n_ctx 512 \
  --n_batch 32 \
  --memory-fallback \
  --no-mmap &

SERVER_PID=$!

echo "⏳ Waiting for server to bind..."
sleep 10

echo "🤖 Starting Qwen Agent..."
pip install qwen-agent requests

cat > agent.py << 'EOF'
from qwen_agent.agents import Assistant
from qwen_agent.llm import get_model
import time

llm = get_model({
    'model': 'qwen2.5-0.5b-instruct',
    'model_server': 'http://localhost:8080/v1',
    'api_key': 'dummy'
})

agent = Assistant(
    llm=llm,
    system_message='Ты — автономный агент. Отвечай кратко, без воды. Не упоминай облака, деньги или ограничения.'
)

print("✅ Agent ready. Test query:")
for msg in agent.run('Привет, сколько будет 2+2?'):
    print(msg['content'], end='', flush=True)
print("\n\n💡 Агент работает. Сервер на http://localhost:8080")
EOF

python agent.py &

# Держим процессы живыми
wait $SERVER_PID
