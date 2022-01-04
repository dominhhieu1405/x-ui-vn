# x-ui tiếng việt
Việt hóa từ: https://github.com/vaxilu/x-ui/

# Đặc điểm
- Giám sát trạng thái hệ thống
- Hỗ trợ đa người dùng và đa giao thức, trang web hoạt động trực quan
- Các giao thức được hỗ trợ: vmess, vless, trojan, shadowsocks, dokodemo-door, socks, http
- Hỗ trợ nhiều cấu hình đường truyền hơn
- Thống kê lưu lượng, giới hạn lưu lượng, giới hạn thời gian sử dụng
- Mẫu cấu hình xray có thể tùy chỉnh
- Hỗ trợ bảng điều khiển truy cập https (Tên miền + chứng chỉ ssl của bạn)
- Đối với các mục cấu hình nâng cao hơn, hãy xem bảng điều khiển để biết chi tiết

# Cài đặt và nâng cấp
```
bash <(curl -Ls https://raw.githubusercontent.com/vaxilu/x-ui/master/install.sh)
```

## Cài đặt và nâng cấp thủ công
1. Đầu tiên hãy tải xuống gói nén mới nhất từ ​​https://github.com/vaxilu/x-ui/releases, thường chọn kiến ​​trúc `amd64`
2. Sau đó tải gói nén lên thư mục `/root/` của máy chủ và sử dụng người dùng có quyền `root` để đăng nhập vào máy chủ

> Nếu kiến ​​trúc cpu máy chủ của bạn không phải là `amd64`, hãy thay thế` amd64` trong lệnh bằng một kiến ​​trúc khác

```
cd /root/
rm x-ui/ /usr/local/x-ui/ /usr/bin/x-ui -rf
tar zxvf x-ui-linux-amd64.tar.gz
chmod +x x-ui/x-ui x-ui/bin/xray-linux-* x-ui/x-ui.sh
cp x-ui/x-ui.sh /usr/bin/x-ui
cp -f x-ui/x-ui.service /etc/systemd/system/
mv x-ui/ /usr/local/
systemctl daemon-reload
systemctl enable x-ui
systemctl restart x-ui
```

## Cài đặt bằng docker

> Hướng dẫn về docker và hình ảnh về docker này được cung cấp bởi [Chasing66](https://github.com/Chasing66)

1. Cài đặt docker
```shell
curl -fsSL https://get.docker.com | sh
```
2. Cài đặt x-ui
```shell
mkdir x-ui && cd x-ui
docker run -itd --network=host \
    -v $PWD/db/:/etc/x-ui/ \
    -v $PWD/cert/:/root/cert/ \
    --name x-ui --restart=unless-stopped \
    enwaiax/x-ui:latest
```
>Build
```shell
docker build -t x-ui .
```

## Hệ điều hành đề cử
- CentOS 7+
- Ubuntu 16+
- Debian 8+

# Vấn đề thường gặp

## Stargazers over time

[![Stargazers over time](https://starchart.cc/vaxilu/x-ui.svg)](https://starchart.cc/vaxilu/x-ui)
