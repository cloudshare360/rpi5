#!/bin/bash
# Memory pressure test to validate swap utilization

echo "🧪 MEMORY PRESSURE TEST"
echo "======================"
echo "This will test if swap is properly utilized under memory pressure"
echo "WARNING: This will consume memory and may slow the system temporarily"
echo ""
read -p "Continue with memory pressure test? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Test cancelled"
    exit 0
fi

echo "Starting memory pressure test..."
echo "Monitor with: ./monitoring/swap_pressure_monitor.sh"
echo ""

# Create memory pressure by allocating memory
stress --vm 2 --vm-bytes 2G --timeout 30s &
STRESS_PID=$!

# Monitor during test
for i in {1..6}; do
    echo "Test progress: ${i}/6 (5 seconds each)"
    echo "Memory: $(free -h | awk 'NR==2{print $7 " available"}')"
    echo "Swap: $(free -h | awk 'NR==3{print $3 " used"}')"
    echo "---"
    sleep 5
done

wait $STRESS_PID
echo "Memory pressure test completed!"
echo ""
echo "Final status:"
free -h
swapon --show
