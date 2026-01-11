# Sử dụng bản slim để ít lỗ hổng nhất
FROM python:3.9-slim

# Tạo thư mục app
WORKDIR /app

# Sao chép và cài đặt thư viện
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy code ứng dụng
COPY app.py .

# ĐIỂM BẢO MẬT QUAN TRỌNG: Chuyển sang user thường
RUN useradd -m myuser
USER myuser

# Chạy ứng dụng
CMD ["python", "app.py"]
