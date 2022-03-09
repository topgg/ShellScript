#########################邮件搜索查询发送工具#################20220309 Author Luke Wayne####################################
#搜索程序初始化 创建相关目录
searchinit(){
	today=$(date "+%Y-%m-%d");
	
	tmpdir=/root/carriecase/$today
	mkdir -p $tmpdir
	mkdir -p $tmpdir/sent/
	mkdir -p $tmpdir/receievd/
}
	##搜索发送的邮件
searchmailsent(){
	for i in $(egrep -H -r "To: .*@icann\.org|To: .*@fbi.gov>|To: .*@usdoj.gov>" /mail/o/onlinenic.com/c/carrie/$searchdir/$searchday | awk -F:  '{print $1}');
		do 
			file=$(egrep -H "From: .*carrie@onlinenic\.com>" $i|awk -F:  '{print $1}'); 
			/bin/cp -rf $file $tmpdir/sent/;
	done; 
}

###搜索收到的邮件

searchmailgot(){
for i in $(egrep -H -r "From: .*@icann\.org|To: .*@fbi.gov>|To: .*@usdoj.gov>" /mail/o/onlinenic.com/c/carrie/$searchdir/$searchday | awk -F:  '{print $1}');
	do 
		file=$(egrep -H "To: .*carrie@onlinenic\.com>" $i|awk -F:  '{print $1}'); 
		/bin/cp -rf $file $tmpdir/receievd/;
	done;

}

### 统计功能

getsummery(){

mailssent=`ls -l $tmpdir/sent/ | grep "^-" | wc -l`
mailsgot=`ls -l $tmpdir/receievd/ | grep "^-" | wc -l`

mailstotal=$((mailssent+mailsgot))
}

#邮件发送功能

SMTP_send(){
	zip -q $tmpdir/carrie$today.zip $tmpdir #必须使用-r , 否则子文件不会被打包
	filename=carrie$today.zip
	fileContent=`cat $tmpdir/carrie$today.zip | base64`
	SMTPSERVER="10.35.0.211 25"
	SMTPUSER="xugy@35.cn"
	smtp_domain="35.cn"
	USER=`echo -n $SMTPUSER|base64`
	PWD=`echo -n "Topgun1302"|base64`
	RCPT=("xugy@35.cn" "zhengzhx@35.cn")
	today=$(date "+%Y-%m-%d")
	subjectName="国安数据整理-Carrie: 过去$totalperiod，总计$mailstotal封邮件"
	mailContext="今天日期 $today,从$starteddate到$endday， $pastperiod 之内，一共发送了$mailssent 封邮件, 收到$mailsgot封邮件,总计$mailstotal封邮件"
	function sendmail {
			(
			for a in "HELO $smtp_domain" "AUTH LOGIN" "$USER" "$PWD" "mail FROM:<$SMTPUSER>"; #必须带上 ; 表示结尾
			do
				sleep 2
				echo $a
				sleep 2;
			done;
			for address in ${RCPT[*]};
			do
				sleep 2
				echo "RCPT TO:<$address>"
				sleep 2;
			done;
	#echo "RCPT TO:${RCPT[0]}"
	#sleep 2
	#echo "RCPT TO:${RCPT[1]}"
	#sleep 2
	echo "data"
	sleep 1
	echo "from:<$SMTPUSER>"
	echo "to:$(IFS=\; ;echo "${RCPT[*]}")" #格式化输出shell数组
	echo "subject:$subjectName"
	echo  "Content-type: multipart/mixed; boundary=\"#BOUNDARY#\""
	echo ""
	echo "--#BOUNDARY#"
	echo "Content-Type: text/plain; charset=UTF-8"
	echo "Content-Transfer-Encoding: quoted-printable"
	echo ""
	echo "$mailContext"
	echo "--#BOUNDARY#"
	echo "Content-Type: application/octet-stream;name=\"$filename\""
	echo "Content-Transfer-Encoding: base64"

	echo ""
	echo "$fileContent"
	echo "--#BOUNDARY#--"
	echo "."

	sleep 1
	echo "QUIT")|telnet $SMTPSERVER
	}

	sendmail
}

###主程序

searchmain(){
searchinit
pastperiod=-7; # 只接受负数
totalperiod=${pastperiod#-} #用字符串方法取绝对值
period="today $pastperiod days";
starteddate=$(date "+%Y-%m-%d" -d "$period")



if [ $pastperiod -gt 0 ];then 
	echo "Usage:$0 's [pastperiod] parament must smaller or equal than 0 "
	exit;
else
	while [ $pastperiod -ne 0 ]
	do	
		period="today $pastperiod days";
		tmpyear=$(date "+%Y" -d "$period")
		searchyear=${tmpyear:2:2};
		searchmonth=$(date "+%m" -d "$period");
		searchday=$(date "+%d" -d "$period");
		searchdir="$searchyear""$searchmonth";
		endday=$tmpyear-$searchmonth-$searchday;
		searchmailsent &
		searchmailgot &
		wait
		pastperiod=$((pastperiod+1))
		
	done
fi

getsummery
SMTP_send

}

searchmain #启动主程序
wait
rm -rf $tmpdir
