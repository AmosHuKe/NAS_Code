#!/bin/sh

# 检测IP是否能够PING通，执行关机操作保护NAS
# 注意整体检测（包括关机及计划任务循环时间）时间不要超过UPS足够坚持的时间

# 【设置】检测ip
ip=192.168.31.1
# 【设置】PING的次数
count=5
# 【设置】再次检测延迟时间(秒)（防止短暂性的断网）
time1=150
# 【设置】关机延迟时间(秒)
time2=5
# 【设置】当前时间
date1=$(date)

echo ' '
echo ' ================= '
echo " 检测的主机IP:=$ip"
echo " ping主机次数:=$count"
echo " 再次检测延迟时间（防止短暂性的断网）=$time1"'s'
echo " 关机延时:=$time2"'s'
echo " 执行时间:=$date1"
echo ' ================= '

# 首次检测
ping -c ${count} ${ip} > /dev/NULL  # PING主机IP指定次数

ret=$?  # 将最后一次的PING返回值赋值给ret，$?表示如果命令执行正常返回0，如果不正常返回其他
if [ $ret -eq 0 ]  # 如果ret值=0，即PING指令执行正常，无错误
then
  echo ' 电源正常 '  # ECHO 显示输出指定内容
  write_log "[Amos]电源正常" 4
else
  echo "检测到交流电源可能异常，${time1} 秒后将再次检测！"
  sleep ${time1}  # 延时秒后再次检测


  # 再次确认检测
  ping -c ${count} ${ip} > /dev/NULL  # 再次PING主机IP
  ret=$?
  if [ $ret -eq 0 ]  # 如果ret值=0，即PING指令执行正常，无错误。
  then
    echo ' 电源恢复正常 '  # ECHO 显示输出指定内容
    write_log "[Amos]电源恢复正常" 4
  else
    echo "检测到电源可能已经中断，在${time2}秒后将关闭NAS"
    write_log "[Amos]检测到电源可能已经中断，将关闭NAS !" 2
    sleep ${time2}  # 延时秒后关机
    /sbin/poweroff # 关机
  fi
fi