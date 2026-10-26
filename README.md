# Kỹ Thuật BigQuery đã áp dụng:
1. **Chuẩn hóa chuỗi văn bản** dùng `initcap()`, `trim()`, `Upper()` để xỷ lí khoảng trống, chuõi chữ
2. **Xử lỹ và định dạng lại giá trị null/rác** dùng `Case When`, `Coalesce` để thay thế và xử lí các giá trị
3. **Ép định dạng ngày tháng an toàn** dùng `Safe.parse_date()` chống bị sập query khi giá trị không hợp lệ
4. **Phát hiện outliers** Áp dụng Tứ phương vị và Phương pháp IQR cùng các hàm `approx_Quantiles()`, `offset` để tìm các đơn hàng có giá bất thường
5. **Cập nhật Data** Sử dụng `Update...Set....Where True** với mỗi câu truy vấn để cập nhật lên bảng mà không làm mất data
