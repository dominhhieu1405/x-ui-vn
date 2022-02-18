## Swap Ram ảo
### Tạo swap
Tạo file dung lượng **1G** lưu ở **/swapfile**

    sudo fallocate -l 1G /swapfile

### Khởi động swap
Đổi quyền để chỉ root mới sửa file

    sudo chmod 600 /swapfile

Tạo swap từ file đã tạo

    sudo mkswap /swapfile

Kích hoạt file swap

    sudo swapon /swapfile

### Làm cho file swap hoạt động khi khởi động lại
Sao lưu file ***/etc/fstab***

    sudo cp /etc/fstab /etc/fstab.bak
Đặt chạy swap

    echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab

### Cài đặt swap
Sửa file /etc/sysctl.conf

    sudo nano /etc/sysctl.conf

thêm 2 dòng:


    vm.swappiness=10
    vm.vfs_cache_pressure=50


