# NixOS Performance Optimization Guide

This comprehensive guide documents performance optimization techniques, monitoring tools, and best practices for different host types in this NixOS configuration. The system is designed for maximum performance while maintaining security and reliability.

## Table of Contents

- [Performance Philosophy](#performance-philosophy)
- [Host-Specific Optimizations](#host-specific-optimizations)
  - [Desktop Performance](#desktop-performance)
  - [Laptop Performance and Power Management](#laptop-performance-and-power-management)
  - [Server Performance](#server-performance)
- [ZFS Performance Tuning](#zfs-performance-tuning)
- [Kernel Parameter Optimization](#kernel-parameter-optimization)
- [Memory Management](#memory-management)
- [Storage I/O Optimization](#storage-io-optimization)
- [Network Performance](#network-performance)
- [Performance Monitoring](#performance-monitoring)
- [Benchmarking Tools](#benchmarking-tools)
- [Performance Analysis](#performance-analysis)
- [Troubleshooting Performance Issues](#troubleshooting-performance-issues)

## Performance Philosophy

This NixOS configuration follows a performance-first approach with these key principles:

1. **Host-Specific Optimization**: Each host type is optimized for its specific use case
2. **Predictable Performance**: Consistent performance through proper resource management
3. **Observability**: Comprehensive monitoring and metrics collection
4. **Scalable Architecture**: Performance optimizations that scale with workload

## Host-Specific Optimizations

### Desktop Performance

The desktop configuration prioritizes maximum performance for development and productivity workloads.

#### CPU Configuration
```nix
# CPU governor for maximum performance
powerManagement.cpuFreqGovernor = "performance";

# Intel-specific optimizations
boot.kernelModules = [ "kvm-intel" ];
```

#### Memory Configuration
```nix
# Large swap for desktop applications
swap = {
  size = "16GB";  # Supports large desktop applications
  encrypted = true;  # LUKS encryption
};
```

#### ZFS Optimizations
```nix
# Desktop ZFS dataset optimizations
"local/root" = {
  recordsize = "1M";        # Optimized for system files
  compression = "zstd";     # Balanced compression/performance
};

"local/nix" = {
  recordsize = "1M";        # Large files (Nix store packages)
  compression = "zstd";
  "com.sun:auto-snapshot" = "false"; # No snapshots for Nix store
};

"safe/persist" = {
  recordsize = "128K";      # Mixed workload optimization
  compression = "zstd";
};

"safe/home" = {
  recordsize = "128K";      # User files mixed workload
  compression = "zstd";
};
```

**Performance Characteristics**:
- **Sequential Read/Write**: Optimized for large files with 1M recordsize
- **Random I/O**: Balanced 128K recordsize for mixed workloads
- **Compression**: ZSTD provides excellent ratios with minimal CPU overhead
- **Deduplication**: Disabled for performance (not needed with Nix store)

### Laptop Performance and Power Management

The laptop configuration balances performance with battery life and thermal management.

#### Power Management with TLP
```nix
services.tlp = {
  enable = true;
  settings = {
    # CPU frequency scaling governor settings
    CPU_SCALING_GOVERNOR_ON_AC = "performance";
    CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
    
    # CPU energy performance policy
    CPU_ENERGY_PERF_POLICY_ON_AC = "performance";
    CPU_ENERGY_PERF_POLICY_ON_BAT = "power";
    
    # Platform power settings
    PLATFORM_PROFILE_ON_AC = "performance";
    PLATFORM_PROFILE_ON_BAT = "low-power";
    
    # SATA link power management
    SATA_LINKPWR_ON_AC = "max_performance";
    SATA_LINKPWR_ON_BAT = "min_power";
    
    # PCIe active state power management
    PCIE_ASPM_ON_AC = "default";
    PCIE_ASPM_ON_BAT = "powersupersave";
  };
};
```

#### Thermal Management
```nix
# Thermal control systems
services.thermald.enable = true;

# CPU thermal throttling
boot.kernelParams = [
  "intel_pstate=active"     # Intel P-State driver
  "processor.max_cstate=2"  # Limit CPU C-states for responsiveness
];
```

#### Memory Optimization for Laptops
```nix
# Laptop-specific memory settings
boot.kernel.sysctl = {
  "vm.swappiness" = 1;           # Minimize swapping
  "vm.vfs_cache_pressure" = 50;  # Cache tuning
  "vm.dirty_ratio" = 15;         # Dirty page ratio
  "vm.dirty_background_ratio" = 5;  # Background write ratio
};
```

#### Storage Optimization
```nix
# SSD optimization for laptops
services.fstrim.enable = true;

# Filesystem mount options for laptops
fileSystems."/".options = [
  "noatime"        # Reduce SSD writes
  "compress=zstd"  # Compression for ZFS
];
```

### Server Performance

The server configuration prioritizes 24/7 stability, low latency, and resource efficiency.

#### CPU Performance Tuning
```nix
boot = {
  # Server-specific kernel parameters for optimal performance
  kernelParams = [
    "nohz_full=1-15"                  # CPU isolation for better performance
    "rcu_nocbs=1-15"                  # RCU callback offloading
    "tsc=reliable"                    # Trust TSC clock source
    "processor.max_cstate=1"          # Limit C-states for lower latency
    "idle=poll"                       # Use idle=poll for low latency
  ];
  
  # Performance-oriented modules
  kernelModules = [ "cpufreq_performance" ];
};
```

**Server CPU Optimization Features**:
- **CPU Isolation**: Dedicates CPU cores for critical server processes
- **RCU Offloading**: Reduces kernel overhead on application CPUs
- **Low Latency**: Minimized CPU sleep states for consistent performance
- **Reliable Timing**: Optimized clock sources for server applications

#### Resource Limits
```nix
systemd.settings.Manager = {
  DefaultLimitNOFILE = 65536;          # File descriptor limit
  DefaultLimitNPROC = 32768;           # Process limit
};
```

#### Network Performance Tuning
```nix
boot.kernel.sysctl = {
  # TCP performance
  "net.core.rmem_max" = 134217728;
  "net.core.wmem_max" = 134217728;
  "net.ipv4.tcp_rmem" = "4096 87380 134217728";
  "net.ipv4.tcp_wmem" = "4096 65536 134217728";
  
  # Connection tracking
  "net.netfilter.nf_conntrack_max" = 524288;
};
```

#### Storage I/O Optimization
```nix
# I/O scheduler optimization
services.udev.extraRules = ''
  # SSD optimization
  ACTION=="add|change", KERNEL=="sd[a-z]", ATTR{queue/rotational}=="0", ATTR{queue/scheduler}="mq-deadline"
  
  # HDD optimization  
  ACTION=="add|change", KERNEL=="sd[a-z]", ATTR{queue/rotational}=="1", ATTR{queue/scheduler}="bfq"
'';

# Filesystem optimizations
boot.kernel.sysctl = {
  "vm.dirty_background_ratio" = 1;
  "vm.dirty_ratio" = 5;
  "vm.swappiness" = 10;
};
```

## ZFS Performance Tuning

### ZFS Configuration Principles

This configuration uses ZFS with optimizations for each host type:

#### Pool-Level Optimizations
```nix
zpool.options = {
  ashift = "12";              # 4K sector alignment for modern drives
  autotrim = "on";           # Automatic TRIM for SSD longevity
  compression = "zstd";       # ZSTD compression for space/performance
  atime = "off";             # Disable access time updates
  xattr = "sa";              # Extended attributes in system attributes
  dnodesize = "auto";        # Dynamic dnode sizing
  normalization = "formD";    # Unicode normalization
  relatime = "on";           # Relative access time updates
};
```

#### Record Size Optimization

| Dataset Type | Record Size | Use Case | Performance Benefit |
|-------------|-------------|----------|-------------------|
| System Files (`local/root`) | 1M | Large system files, binaries | Maximum sequential throughput |
| Nix Store (`local/nix`) | 1M | Large packages, derivations | Optimal for large file reads |
| User Data (`safe/home`) | 128K | Mixed file sizes | Balanced random/sequential I/O |
| Persistent Data (`safe/persist`) | 128K | Configuration, logs | Good for small-to-medium files |

### ZFS ARC (Adaptive Replacement Cache) Tuning

```nix
# ARC tuning for optimal memory usage
boot.kernel.sysctl = {
  # Limit ZFS ARC based on available RAM
  "vm.swappiness" = 1;
  "vm.vfs_cache_pressure" = 50;
};

# ZFS kernel module parameters
boot.extraModprobeConfig = ''
  # Limit ARC size (adjust for your system)
  options zfs zfs_arc_max=8589934592  # 8GB max
  options zfs zfs_arc_min=1073741824  # 1GB min
'';
```

**ARC Sizing Guidelines**:
- **Desktop**: 50-75% of RAM for ARC
- **Laptop**: 25-50% of RAM (preserve battery life)
- **Server**: 75-90% of RAM (dedicated workload)

### ZFS Performance Monitoring

```bash
# Monitor ARC efficiency
arc_summary | grep "Hit Rates"

# Check dataset usage and compression
zfs list -o space,compressratio

# Monitor I/O patterns
zpool iostat -v 5 12

# Check pool status and performance
zpool status -v
```

## Kernel Parameter Optimization

### Common Kernel Parameters

#### Desktop Optimizations
```nix
boot.kernelParams = [
  "intel_pstate=active"       # Intel P-State driver for better performance
  "mitigations=off"          # Disable CPU vulnerability mitigations for performance
  "transparent_hugepage=madvise" # Optimize memory allocation
];
```

#### Laptop Optimizations  
```nix
boot.kernelParams = [
  "intel_pstate=active"       # Intel P-State driver
  "processor.max_cstate=2"    # Limit CPU C-states for responsiveness
  "pcie_aspm=force"          # Force PCIe power management
  "i915.enable_psr=1"        # Panel Self Refresh for battery life
];
```

#### Server Optimizations
```nix
boot.kernelParams = [
  "nohz_full=1-15"           # CPU isolation
  "rcu_nocbs=1-15"           # RCU callback offloading  
  "tsc=reliable"             # Trust TSC clock source
  "processor.max_cstate=1"   # Limit C-states for latency
  "idle=poll"                # Use idle=poll for low latency
  "isolcpus=1-15"           # Isolate CPUs from scheduler
];
```

## Memory Management

### System Memory Optimization

#### Desktop Memory Settings
```nix
boot.kernel.sysctl = {
  # Desktop workload optimizations
  "vm.swappiness" = 60;              # Standard swapping behavior
  "vm.vfs_cache_pressure" = 100;     # Standard cache pressure
  "vm.dirty_ratio" = 20;             # Allow more dirty pages
  "vm.dirty_background_ratio" = 10;  # Background writeback threshold
};
```

#### Laptop Memory Settings  
```nix
boot.kernel.sysctl = {
  # Battery-optimized memory settings
  "vm.swappiness" = 1;               # Minimize swapping to preserve SSD
  "vm.vfs_cache_pressure" = 50;      # Preserve caches longer
  "vm.dirty_ratio" = 15;             # Reduce dirty pages for battery
  "vm.dirty_background_ratio" = 5;   # Earlier background writeback
  "vm.laptop_mode" = 1;              # Enable laptop mode
};
```

#### Server Memory Settings
```nix  
boot.kernel.sysctl = {
  # Server stability optimizations
  "vm.swappiness" = 10;              # Minimal swapping for server stability
  "vm.vfs_cache_pressure" = 50;      # Preserve filesystem caches
  "vm.dirty_ratio" = 5;              # Quick writeback for data integrity
  "vm.dirty_background_ratio" = 1;   # Very early background writeback
  "vm.overcommit_memory" = 2;        # Conservative memory overcommit
};
```

### Swap Configuration

#### Desktop Swap (16GB)
```nix
# Large swap for desktop applications (IDEs, browsers, VMs)
swapDevices = [{
  device = "/dev/mapper/swap";
  size = 16 * 1024;  # 16GB
}];
```

#### Laptop Swap (8GB)  
```nix
# Moderate swap with suspend-to-disk support
swapDevices = [{
  device = "/dev/mapper/swap";  
  size = 8 * 1024;  # 8GB
}];

# Enable hibernation
powerManagement.resumeCommands = "systemctl restart bluetooth";
```

#### Server Swap (4GB)
```nix
# Minimal swap for server stability
swapDevices = [{
  device = "/dev/mapper/swap";
  size = 4 * 1024;  # 4GB minimal
}];
```

## Storage I/O Optimization

### I/O Schedulers

```nix
# Automatic I/O scheduler selection based on drive type
services.udev.extraRules = ''
  # SSD optimization (mq-deadline for low latency)
  ACTION=="add|change", KERNEL=="sd[a-z]", ATTR{queue/rotational}=="0", ATTR{queue/scheduler}="mq-deadline"
  
  # NVMe optimization (none - no scheduler needed)
  ACTION=="add|change", KERNEL=="nvme[0-9]*", ATTR{queue/scheduler}="none"
  
  # HDD optimization (BFQ for throughput and fairness)
  ACTION=="add|change", KERNEL=="sd[a-z]", ATTR{queue/rotational}=="1", ATTR{queue/scheduler}="bfq"
'';
```

### Filesystem Mount Options

#### Performance-Focused Mounts
```nix
fileSystems = {
  "/" = {
    options = [
      "noatime"              # Disable access time updates
      "compress=zstd"        # Enable ZFS compression
      "zfsutil"             # Use ZFS utilities
    ];
  };
  
  "/nix" = {
    options = [
      "noatime"              # Critical for Nix store performance
      "compress=zstd"        # Compress Nix packages
    ];
  };
};
```

### SSD Optimization

```nix
# Enable automatic TRIM for SSDs
services.fstrim = {
  enable = true;
  interval = "weekly";       # Weekly TRIM operations
};

# ZFS automatic TRIM
boot.zfs.extraPools = [ "rpool" ];
```

## Network Performance

### High-Performance Network Configuration

#### Server Network Tuning
```nix
boot.kernel.sysctl = {
  # TCP buffer sizes (128MB max)
  "net.core.rmem_max" = 134217728;
  "net.core.wmem_max" = 134217728;
  "net.ipv4.tcp_rmem" = "4096 87380 134217728";
  "net.ipv4.tcp_wmem" = "4096 65536 134217728";
  
  # TCP performance optimizations
  "net.ipv4.tcp_congestion_control" = "bbr";  # BBR congestion control
  "net.ipv4.tcp_slow_start_after_idle" = 0;   # Disable slow start after idle
  "net.ipv4.tcp_window_scaling" = 1;          # Enable window scaling
  "net.ipv4.tcp_timestamps" = 1;              # Enable timestamps
  
  # Connection tracking
  "net.netfilter.nf_conntrack_max" = 524288;
  "net.netfilter.nf_conntrack_tcp_timeout_established" = 1200;
  
  # Network buffer limits
  "net.core.netdev_max_backlog" = 5000;
  "net.core.somaxconn" = 65536;
};
```

### Network Interface Optimization

```nix
# High-performance network interface settings
systemd.network = {
  networks."10-ethernet" = {
    matchConfig.Name = "enp*";
    networkConfig = {
      DHCP = "yes";
      MulticastDNS = true;
    };
    dhcpV4Config = {
      RouteMetric = 10;
    };
    linkConfig = {
      # Optimize for performance
      TCPSegmentationOffload = true;
      GenericSegmentationOffload = true;  
      GenericReceiveOffload = true;
      LargeReceiveOffload = true;
    };
  };
};
```

## Performance Monitoring

### System Monitoring Tools

This configuration includes comprehensive monitoring capabilities:

```nix
environment.systemPackages = with pkgs; [
  # System monitoring
  htop btop                    # Process monitors
  iotop                        # I/O monitoring
  nethogs                      # Network usage by process
  
  # Performance analysis
  perf-tools                   # Linux perf tools
  sysstat                      # System activity reporter
  
  # Storage monitoring  
  ncdu                         # Disk usage analyzer
  smartmontools               # SMART disk monitoring
  
  # Network monitoring
  bandwhich                    # Network utilization by process
  iftop                       # Network interface monitoring
  
  # System information
  hwinfo                      # Hardware information
  lshw                        # Hardware lister
  dmidecode                   # DMI table decoder
];
```

### Prometheus Monitoring (Server)

```nix
# Enable Prometheus node exporter on servers
services.prometheus.exporters.node = {
  enable = true;
  enabledCollectors = [ 
    "systemd"      # SystemD service metrics
    "processes"    # Process information
    "diskstats"    # Disk I/O statistics
    "filefd"       # File descriptor usage
    "network"      # Network interface stats
    "stat"         # CPU and kernel stats
    "meminfo"      # Memory statistics
    "loadavg"      # Load average
  ];
  port = 9100;
};
```

### Custom Monitoring Scripts

Create monitoring scripts for specific metrics:

```bash
#!/usr/bin/env bash
# /persist/scripts/performance-monitor.sh

echo "=== System Performance Report ==="
echo "Date: $(date)"
echo

echo "=== CPU Information ==="
lscpu | grep -E "Model name|CPU\(s\)|Thread|MHz"
echo

echo "=== Memory Usage ==="
free -h
echo

echo "=== Disk Usage ==="
df -h | grep -E "^/dev"
echo

echo "=== ZFS Status ==="
zpool status
echo

echo "=== Top Processes by CPU ==="
ps aux --sort=-%cpu | head -10
echo

echo "=== Top Processes by Memory ==="
ps aux --sort=-%mem | head -10
echo

echo "=== Network Connections ==="
ss -tuln | wc -l
echo "Active connections: $(ss -tuln | wc -l)"
```

## Benchmarking Tools

### Available Benchmarking Packages

```nix
environment.systemPackages = with pkgs; [
  # Command-line benchmarking
  hyperfine                    # Command-line benchmarking tool
  
  # System benchmarking  
  sysbench                     # Multi-threaded benchmark tool
  
  # Storage benchmarking
  fio                          # Flexible I/O tester
  iozone                       # Filesystem benchmark
  bonnie                       # Hard drive benchmark
  
  # Network benchmarking
  iperf3                       # Network performance measurement
  netperf                      # Network performance benchmark
  
  # CPU benchmarking
  stress-ng                    # CPU stress testing
  
  # Graphics benchmarking (desktop)
  glmark2                      # OpenGL benchmark
  unigine-valley              # Graphics benchmark
];
```

### Benchmarking Examples

#### CPU Performance
```bash
# Multi-core CPU benchmark
sysbench cpu --threads=$(nproc) run

# Stress test all CPU cores
stress-ng --cpu $(nproc) --timeout 60s --metrics-brief
```

#### Memory Performance  
```bash
# Memory throughput test
sysbench memory --threads=$(nproc) --memory-total-size=10G run

# Memory latency test
sysbench memory --memory-oper=read --threads=1 run
```

#### Storage Performance
```bash
# Random I/O performance
fio --name=random-rw --ioengine=libaio --iodepth=32 --rw=randrw --bs=4k --direct=1 --size=1G --numjobs=4 --runtime=60 --group_reporting

# Sequential I/O performance  
fio --name=sequential-rw --ioengine=libaio --iodepth=1 --rw=rw --bs=1M --direct=1 --size=1G --numjobs=1 --runtime=60

# ZFS-specific I/O test
fio --name=zfs-test --directory=/persist --ioengine=libaio --iodepth=32 --rw=randrw --bs=64k --direct=0 --size=1G --numjobs=2 --runtime=60
```

#### Network Performance
```bash
# Network throughput (requires iperf3 server)
iperf3 -c server.example.com -t 60 -P 4

# Local network interface maximum
iperf3 -c localhost -t 30
```

### Performance Testing Methodology

1. **Baseline Measurement**: Establish baseline performance metrics
2. **Isolated Testing**: Test individual components separately  
3. **Load Testing**: Test under realistic workloads
4. **Regression Testing**: Compare before/after optimization changes
5. **Documentation**: Record results and configuration changes

#### Benchmark Script Template
```bash
#!/usr/bin/env bash
# Performance benchmark suite

RESULTS_DIR="/tmp/performance-results-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$RESULTS_DIR"

echo "Starting performance benchmark suite..."
echo "Results will be saved to: $RESULTS_DIR"

# System information
{
    echo "=== System Information ==="
    uname -a
    lscpu
    free -h
    df -h
    zpool status
} > "$RESULTS_DIR/system-info.txt"

# CPU benchmark
echo "Running CPU benchmark..."
sysbench cpu --threads=$(nproc) run > "$RESULTS_DIR/cpu-benchmark.txt"

# Memory benchmark  
echo "Running memory benchmark..."
sysbench memory --threads=$(nproc) run > "$RESULTS_DIR/memory-benchmark.txt"

# Storage benchmark
echo "Running storage benchmark..."
fio --name=storage-test --ioengine=libaio --iodepth=32 --rw=randrw --bs=4k --direct=1 --size=1G --runtime=60 --output="$RESULTS_DIR/storage-benchmark.txt"

echo "Benchmark complete. Results saved to: $RESULTS_DIR"
```

## Performance Analysis  

### Performance Monitoring Commands

#### Real-Time System Monitoring
```bash
# Overall system performance
htop

# I/O performance monitoring
iotop -o

# Network activity monitoring
nethogs

# Disk usage and performance
ncdu /

# ZFS performance monitoring
watch -n 5 'zpool iostat -v'
```

#### Historical Performance Analysis
```bash
# System activity over time
sar -u 1 60    # CPU usage
sar -r 1 60    # Memory usage  
sar -d 1 60    # Disk activity
sar -n DEV 1 60 # Network activity

# Process performance history
pidstat -u -r -d 1 60

# System load analysis
uptime
cat /proc/loadavg
```

#### Performance Profiling
```bash
# Profile system-wide for 60 seconds
perf record -a -g sleep 60
perf report

# Profile specific process
perf record -p PID -g sleep 30
perf report

# System call tracing
strace -c -p PID

# Memory usage profiling
valgrind --tool=memcheck --leak-check=full program
```

### ZFS Performance Analysis

#### ARC Efficiency Monitoring
```bash
# ARC summary and hit rates
arc_summary

# ARC statistics over time  
watch -n 5 'cat /proc/spl/kstat/zfs/arcstats | grep -E "hits|misses|size"'

# ZFS dataset performance
zfs get compressratio,used,available
```

#### ZFS I/O Analysis
```bash
# Pool I/O statistics
zpool iostat -v 5

# Dataset I/O patterns
zpool iostat -v rpool 5 12

# ZFS event monitoring
zpool events -v

# Check for I/O errors
zpool status -v
```

## Troubleshooting Performance Issues

### Common Performance Problems

#### High CPU Usage
```bash
# Identify CPU-intensive processes
top -o %CPU
ps aux --sort=-%cpu | head -20

# Check CPU frequency scaling
cat /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor
cat /sys/devices/system/cpu/cpu*/cpufreq/scaling_cur_freq

# Verify CPU isolation (servers)
cat /sys/devices/system/cpu/isolated
```

**Solutions**:
- Verify CPU governor settings
- Check for thermal throttling
- Review process priorities and nice values
- Consider CPU affinity for critical processes

#### Memory Pressure
```bash
# Memory usage breakdown
free -h
cat /proc/meminfo

# Swap usage
swapon -s
cat /proc/swaps

# Memory-intensive processes  
ps aux --sort=-%mem | head -20

# Check for memory leaks
valgrind --tool=memcheck --leak-check=full program
```

**Solutions**:
- Adjust ZFS ARC limits
- Tune kernel memory parameters  
- Review application memory usage
- Consider adding more RAM or swap

#### Storage Performance Issues
```bash
# Check I/O utilization
iostat -x 5

# Identify I/O-intensive processes
iotop -o

# ZFS performance issues
zpool iostat -v 5
arc_summary

# Check disk health
smartctl -a /dev/sdX
```

**Solutions**:
- Verify I/O scheduler settings
- Check ZFS recordsize settings
- Monitor disk health and replace if needed
- Consider SSD upgrade for performance

#### Network Performance Issues
```bash
# Network interface statistics
ip -s link show

# Network bandwidth usage
iftop
nethogs

# Network latency testing
ping -c 10 target
mtr target

# TCP connection analysis
ss -tuln
netstat -i
```

**Solutions**:
- Verify network interface settings
- Check network hardware and cables
- Review network congestion control
- Optimize TCP buffer sizes

### Performance Debugging Checklist

1. **System Resources**:
   - [ ] Check CPU usage and thermal throttling
   - [ ] Verify memory availability and swap usage
   - [ ] Monitor disk I/O and space usage
   - [ ] Check network utilization

2. **ZFS Performance**:
   - [ ] Verify ARC hit rates (should be >90%)
   - [ ] Check compression ratios
   - [ ] Monitor pool I/O patterns
   - [ ] Verify dataset recordsize settings

3. **Kernel Configuration**:
   - [ ] Verify kernel parameters are applied
   - [ ] Check I/O scheduler settings
   - [ ] Confirm CPU governor configuration  
   - [ ] Review memory management settings

4. **Application Performance**:
   - [ ] Profile application resource usage
   - [ ] Check for memory leaks
   - [ ] Monitor I/O patterns
   - [ ] Review process priorities

### Emergency Performance Recovery

If system performance is severely degraded:

1. **Immediate Actions**:
```bash
# Kill resource-intensive processes
pkill -f high-cpu-process

# Reduce system load
echo 1 > /proc/sys/vm/drop_caches  # Clear caches
sync                               # Flush pending writes
```

2. **ZFS Emergency Commands**:
```bash  
# Reduce ARC pressure
echo 1073741824 > /sys/module/zfs/parameters/zfs_arc_max  # 1GB

# Clear ZFS caches
zpool scrub -s rpool  # Stop scrub if running
```

3. **System Recovery**:
```bash
# Revert to performance mode
echo performance > /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor

# Clear swap if possible
swapoff -a && swapon -a
```

This performance optimization guide provides comprehensive coverage of performance tuning techniques, monitoring tools, and troubleshooting procedures for all host types in the NixOS configuration. Regular monitoring and benchmarking ensure optimal system performance while maintaining security and reliability.