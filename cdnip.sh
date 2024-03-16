#!/bin/bash
export LANG=en_US.UTF-8
point=oppoint
IP_ADDR=opv4v6
x_email=opmail
hostname=opym
zone_id=opcfid
api_key=opcfkey
pause=true
clien=opcli
 
CFST_URL_R="opspd"

CFST_N=opnum

CFST_T=4

CFST_DN=opsnum

CFST_TL=opup

CFST_TLL=opdo

CFST_SL=opsd

telegramBotToken=optgken
telegramBotUserId=optgid

CFST_SPD=-dd
ymorip=1
domain=opymyj
subdomain=opymmc
ymoryms=1
token=oppushtk
sleepTime=30
tgapi=api.telegram.org

tgaction(){
if [[ -z ${telegramBotToken} ]]; then
   echo "未配置TG推送"
else
   message_text=$pushmessage
   MODE='HTML'
   URL="https://${tgapi}/bot${telegramBotToken}/sendMessage"
   res=$(timeout 20s curl -s -X POST $URL -d chat_id=${telegramBotUserId}  -d parse_mode=${MODE} -d text="${message_text}")
   if [ $? == 124 ];then
      echo 'TG_api请求超时,请检查网络是否重启完成并是否能够访问TG'
   fi
   resSuccess=$(echo "$res" | jq -r ".ok")
   if [[ $resSuccess = "true" ]]; then
      echo "TG推送成功";
      else
      echo "TG推送失败，请检查TG机器人token和ID";
   fi
fi
if [[ -z ${token} ]]; then
   echo "未配置PushPlus推送"
else
   P_message_text=$pushmessage
   res=$(timeout 20s curl -s -X POST "http://www.pushplus.plus/send" -d "token=${token}" -d "title=Cloudflare优选IP推送通知" -d "content=${P_message_text}" -d "template=html")
   if [ $? == 124 ];then
      echo 'PushPlus请求超时，请检查网络是否正常'
   fi
   resCode=$(echo "$res" | jq -r ".code")
   if [[ $resCode = 200 ]]; then
      echo "PushPlus推送成功";
   else
      echo "PushPlus推送失败，请检查PushPlusToken是否填写正确";
   fi
fi
}

cd /root/cfipopw/ && rm -rf informlog && bash cdnac.sh
if [ "$ymorip" == "1" ]; then
sed -i '/api.cloudflare.com/d' /etc/hosts
proxy="false";
max_retries=5
for ((i=1; i<=$max_retries; i++)); do
    res=$(curl -sm10 -X GET "https://api.cloudflare.com/client/v4/zones/${zone_id}" -H "X-Auth-Email:$x_email" -H "X-Auth-Key:$api_key" -H "Content-Type:application/json")
    resSuccess=$(echo "$res" | jq -r ".success")
    if [[ $resSuccess == "true" ]]; then
        echo "Cloudflare账号登陆成功!"
        break
    elif [ $i -eq $max_retries ]; then
        sed -i '/api.cloudflare.com/d' /etc/hosts
        echo "尝试5次登陆CF失败，检查CF邮箱、区域ID、API Key，这三者信息是否填写正确，或者查下当前代理的网络能否打开Cloudflare官网？"
        pushmessage="尝试5次登陆CF失败，检查CF邮箱、区域ID、API Key，这三者信息是否填写正确，或者查下当前代理的网络能否打开Cloudflare官网？"
        tgaction
        exit
    else
        echo "Cloudflare账号登陆失败，尝试重连 ($i/$max_retries)..."
	sed -i '/api.cloudflare.com/d' /etc/hosts
        echo -e "104.18.12.137 api.cloudflare.com\n104.16.160.55 api.cloudflare.com\n104.16.96.55 api.cloudflare.com" >> /etc/hosts
        sleep 2
    fi
done
if [ ! "$ymoryms" == "1" ]; then
num=${#hostname[*]};
if [ "$CFST_DN" -le $num ] ; then
CFST_DN=$num;
fi
fi
fi
if [ "$IP_ADDR" = "ipv6" ] ; then
    if [ ! -f "ipv6.txt" ]; then
        echo "当前工作模式为ipv6，但该目录下没有【ipv6.txt】，请配置【ipv6.txt】。下载地址：https://github.com/XIU2/CloudflareSpeedTest/releases";
        exit 2;
        else
            echo "当前工作模式为ipv6";
    fi
    else
        echo "当前工作模式为ipv4";
fi

case $clien in
  "8") CLIEN=vssr;;
  "7") CLIEN=v2raya;;
  "6") CLIEN=bypass;;
  "5") CLIEN=openclash;;
  "4") CLIEN=clash;;
  "3") CLIEN=shadowsocksr;;
  "2") CLIEN=passwall2;;
  "1") CLIEN=passwall;;
  *) pause=false;;
esac

if [ "$pause" = "false" ] ; then
echo "按要求未停止科学上网服务";
else
/etc/init.d/$CLIEN stop;
echo "已停止$CLIEN";
fi

if [ "$IP_ADDR" = "ipv6" ] ; then
    ./cfst -tp $point $CFST_URL_R -t $CFST_T -n $CFST_N -dn $CFST_DN -p $CFST_DN -tl $CFST_TL -tll $CFST_TLL -sl $CFST_SL -f ipv6.txt $CFST_SPD -dt 8
    else
    ./cfst -tp $point $CFST_URL_R -t $CFST_T -n $CFST_N -dn $CFST_DN -p $CFST_DN -tl $CFST_TL -tll $CFST_TLL -sl $CFST_SL $CFST_SPD -dt 8
fi

if [ -f "/root/cfipopw/result.csv" ]; then
second_line=$(sed -n '2p' /root/cfipopw/result.csv | tr -d '[:space:]')
if [ -z "$second_line" ]; then
echo "优选IP失败，请尝试更换端口或者重新执行一次" && sleep 3
pushmessage="优选IP失败，请尝试更换端口或者重新执行一次"
tgaction
exit
fi
num=$CFST_DN
new_num=$((num + 1))
if [ $(awk -F, 'NR==2 {print $6}' /root/cfipopw/result.csv) == 0.00 ]; then
awk -F, "NR<=$new_num" /root/cfipopw/result.csv > /root/cfipopw/new_result.csv
mv /root/cfipopw/new_result.csv /root/cfipopw/result.csv
fi
if [[ $(awk -F ',' 'NR==12 {print $1}' /root/cfipopw/result.csv) ]]; then
awk -F ',' 'NR>1 && NR<=11 {print $1}' /root/cfipopw/result.csv > /root/cfipopw/new_result.csv
mv /root/cfipopw/new_result.csv /root/cfipopw/result.csv
fi
sed -i '/api.cloudflare.com/d' /etc/hosts
#goodip=$(awk -F ',' 'NR > 1 {print $1}' /root/cfipopw/result.csv | sed -n 1p)
#echo "$goodip api.cloudflare.com" >> /etc/hosts
else
echo "优选IP中断，未生成result.csv文件，请尝试更换端口或者重新执行一次" && sleep 3
pushmessage="优选IP中断，未生成result.csv文件，请尝试更换端口或者重新执行一次"
tgaction
exit
fi

echo "测速完毕";
if [ "$pause" = "false" ] ; then
		echo "按要求未重启科学上网服务";
		sleep 3;
else
		/etc/init.d/$CLIEN restart;
		echo "已重启$CLIEN";
		echo "请稍等$sleepTime秒";
		sleep $sleepTime;
fi

ymonly(){
echo "正在更新解析：多个优选IP解析到一个域名。请稍后...";
url="https://api.cloudflare.com/client/v4/zones/$zone_id/dns_records"
params="name=${subdomain}.${domain}&type=A,AAAA"
response=$(curl -sm10 -X GET "$url?$params" -H "X-Auth-Email: $x_email" -H "X-Auth-Key: $api_key")
if [[ $(echo "$response" | jq -r '.success') == "true" ]]; then
    records=$(echo "$response" | jq -r '.result')
    if [[ $(echo "$records" | jq 'length') -gt 0 ]]; then
        for record in $(echo "$records" | jq -c '.[]'); do
            record_id=$(echo "$record" | jq -r '.id')
            delete_url="$url/$record_id"
            delete_response=$(curl -s -X DELETE "$delete_url" -H "X-Auth-Email: $x_email" -H "X-Auth-Key: $api_key")
            if [[ $(echo "$delete_response" | jq -r '.success') == "true" ]]; then
                echo "成功删除 DNS 记录：$(echo "$record" | jq -r '.name')"
            else
                echo "删除 DNS 记录失败"
            fi
        done
    else
        echo "没有找到指定的 DNS 记录"
    fi
else
    echo "获取 DNS 记录失败"
fi
csv_file='result.csv'
if [[ -f $csv_file ]]; then
    ips=$(awk -F ',' 'NR > 1 {print $1}' "$csv_file")
    for ip in $ips; do
        url="https://api.cloudflare.com/client/v4/zones/$zone_id/dns_records"
        if [[ "$ip" =~ ":" ]]; then
            record_type="AAAA"
        else
            record_type="A"
        fi
        data='{
            "type": "'"$record_type"'",
            "name": "'"$subdomain.$domain"'",
            "content": "'"$ip"'",
            "ttl": 60,
            "proxied": false
        }'
        response=$(curl -s -X POST "$url" -H "X-Auth-Email: $x_email" -H "X-Auth-Key: $api_key" -H "Content-Type: application/json" -d "$data")
        if [[ $(echo "$response" | jq -r '.success') == "true" ]]; then
            echo "IP地址 $ip 成功解析到 ${subdomain}.${domain}"
            echo "IP地址 $ip 成功解析到 ${subdomain}.${domain}" >> informlog
        else
            echo "导入IP地址 $ip 失败"
            echo "导入IP地址 $ip 失败" >> informlog
        fi
        sleep 3
       done
else
    echo "CSV文件 $csv_file 不存在"
fi
}

ym(){
echo "正在更新解析：每个优选IP解析到每个域名。请稍后...";
ipv4Regex="((25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])\.){3,3}(25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])";
x=0;
while [[ ${x} -lt $num ]]; do
    CDNhostname=${hostname[$x]};
    ipAddr=$(sed -n "$((x + 2)),1p" result.csv | awk -F, '{print $1}');
    echo "开始更新第$((x + 1))个---$ipAddr";
    if [[ $ipAddr =~ $ipv4Regex ]]; then
        recordType="A";
    else
        recordType="AAAA";
    fi
    listDnsApi="https://api.cloudflare.com/client/v4/zones/${zone_id}/dns_records?type=${recordType}&name=${CDNhostname}";
    createDnsApi="https://api.cloudflare.com/client/v4/zones/${zone_id}/dns_records";
    res=$(curl -s -X GET "$listDnsApi" -H "X-Auth-Email:$x_email" -H "X-Auth-Key:$api_key" -H "Content-Type:application/json");
    sleep 1
    recordId=$(echo "$res" | jq -r ".result[0].id");
    recordIp=$(echo "$res" | jq -r ".result[0].content");

    if [[ $recordIp = "$ipAddr" ]]; then
        echo "更新失败，获取最快的IP与云端相同";
        resSuccess=false;
    elif [[ $recordId = "null" ]]; then
        res=$(curl -s -X POST "$createDnsApi" -H "X-Auth-Email:$x_email" -H "X-Auth-Key:$api_key" -H "Content-Type:application/json" --data "{\"type\":\"$recordType\",\"name\":\"$CDNhostname\",\"content\":\"$ipAddr\",\"proxied\":$proxy}");
        resSuccess=$(echo "$res" | jq -r ".success");
    else
        updateDnsApi="https://api.cloudflare.com/client/v4/zones/${zone_id}/dns_records/${recordId}";
        res=$(curl -s -X PUT "$updateDnsApi"  -H "X-Auth-Email:$x_email" -H "X-Auth-Key:$api_key" -H "Content-Type:application/json" --data "{\"type\":\"$recordType\",\"name\":\"$CDNhostname\",\"content\":\"$ipAddr\",\"proxied\":$proxy}");
        resSuccess=$(echo "$res" | jq -r ".success");
    fi

    if [[ $resSuccess = "true" ]]; then
        echo "$CDNhostname更新成功";
    else
        echo "$CDNhostname更新失败";
    fi
    x=$((x + 1));
    sleep 3;
done > informlog
}

if [ "$ymorip" == "1" ]; then
if [ "$ymoryms" == "1" ]; then
ymonly
else
ym
fi
else
echo "优选IP排名如下" > informlog
awk -F ',' 'NR > 1 {print $1}' result.csv >> informlog
fi
bash cdnac.sh
pushmessage=$(cat informlog);
tgaction
echo
echo "切记：在软路由-计划任务选项中，加入优选IP自动执行时间的cron表达式"
echo "比如每天早上三点执行：0 3 * * * cd /root/cfipopw/ && bash cdnip.sh"
echo
exit
