# 🚀 Quick Usage Examples

## For Raspberry Pi 5 Hardware Testing:

```bash
# 1. Make scripts executable
chmod +x *.sh

# 2. Run hardware drive test (requires sudo)
sudo ./drive_speed_test.sh

# 3. Generate comprehensive report
./complete_speed_report.sh > rpi5_report_$(date +%Y%m%d).txt
```

## For Container/Development Environment:

```bash
# 1. Make scripts executable  
chmod +x *.sh

# 2. Run filesystem test
./filesystem_speed_test.sh

# 3. Generate detailed report
./complete_speed_report.sh > container_report_$(date +%Y%m%d).txt
```

## View Generated Reports:

```bash
# List all reports
ls -la *report*.txt

# View latest report
cat final_speed_report_*.txt
```

## Expected Performance (Raspberry Pi 5):

- **NVMe SSD**: 1000+ MB/s write, 1500+ MB/s read
- **USB 3.0 SSD**: 100-400 MB/s write, 200-500 MB/s read  
- **USB 3.0 HDD**: 50-150 MB/s write, 100-200 MB/s read

See `README.md` for complete documentation.