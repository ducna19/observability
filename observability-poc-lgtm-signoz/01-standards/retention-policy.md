# Retention Policy POC

| Data | POC retention | Production tham khảo |
|---|---:|---:|
| Metrics | 15–30 ngày | 6–13 tháng, có downsampling nếu cần |
| Logs | 7 ngày | 7–30 ngày runtime logs; security/audit lâu hơn |
| Traces | 7 ngày | 3–14 ngày, sampling theo traffic |
| Alerts | 30 ngày | 1 năm |
| Dashboard config | Git | Git |

## Nguyên tắc

- POC không lưu dữ liệu nhạy cảm.
- Không log password, token, secret, PII.
- Nên có masking ở application hoặc collector nếu dùng data thật.
