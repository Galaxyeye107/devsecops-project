# Giai đoạn 1: Build (Sử dụng Image đầy đủ để cài đặt)
FROM python:3.9-slim as builder
WORKDIR /app
COPY requirements.txt .
# Cài đặt thư viện vào một thư mục riêng
RUN pip install --user --no-cache-dir -r requirements.txt

# Giai đoạn 2: Runtime (Image cuối cùng - Cực kỳ tinh gọn)
FROM python:3.9-slim
WORKDIR /app

# Chỉ copy những thư viện đã cài đặt từ giai đoạn builder
COPY --from=builder /root/.local /root/.local
COPY app.py .

# Đảm bảo đường dẫn thư viện chính xác
ENV PATH=/root/.local/bin:$PATH

# ĐIỂM BẢO MẬT: Chạy với User không có quyền root
RUN useradd -m appuser
USER appuser

EXPOSE 5000
CMD ["python", "app.py"]