#!/bin/bash
# 导出mysql数据库表结构到html
# author: Z.kc
# example:
# ./export-mysql-schema.sh localhost 3306 root root test > test.html


if [ $# -lt 5 ]; then
	echo "Usage: export-mysql-schema.sh MYSQL_HOST MYSQL_PORT MYSQL_USER MYSQL_PWD MYSQL_DATABASE > abc.html"
	exit 1
fi

MYSQL_HOST=$1
MYSQL_PORT=$2
MYSQL_USER=$3
MYSQL_PWD=$4
MYSQL_DB=$5


# 关闭警告错误提示
exec 2>&-

DB=$MYSQL_DB
CMD="mysql -h$MYSQL_HOST -u$MYSQL_USER -p$MYSQL_PWD $DB "

TEST=$($CMD -s -N -e "select 1")
if [ "$TEST"x != "1"x ]; then
	exec 2>/dev/tty
	echo "无法连接mysql" >&2
	exit 1
fi

# 获取table
TABLES=`$CMD -e "show tables" 2> /dev/null| tail -n +2`


###########################
# html 头部
echo "<html>"
cat <<EOF
<head><meta http-equiv=Content-Type content="text/html;charset=utf-8">
<style>
.nowrap {
	white-space: nowrap;
}

.hide {
	display: none;
}

body, table, th, td {
	color:             #000;
	background-color:  #fff;
}

img {
	border: 0;
}

table, th, td {
	border: .1em solid #000;
}

table {
	border-collapse:   collapse;
	border-spacing:    0;
}

th, td {
	padding:           0.2em;
}

th {
	font-weight:       bold;
	background-color:  #e5e5e5;
}

th.vtop, td.vtop {
	vertical-align: top;
}

th.vbottom, td.vbottom {
	vertical-align: bottom;
}

@media print {
	.print_ignore {
		display: none;
	}

	.nowrap {
		white-space: nowrap;
	}

	.hide {
		display: none;
	}

	body, table, th, td {
		color:             #000;
		background-color:  #fff;
	}

	img {
		border: 0;
	}

	table, th, td {
		border: .1em solid #000;
	}

	table {
		border-collapse:   collapse;
		border-spacing:    0;
	}

	th, td {
		padding:           0.2em;
	}

	th {
		font-weight:       bold;
		background-color:  #e5e5e5;
	}

	th.vtop, td.vtop {
		vertical-align: top;
	}

	th.vbottom, td.vbottom {
		vertical-align: bottom;
	}
}
</style>
</head>
EOF

################################

echo "<body>"


for TABLE in $TABLES
do

	# 表注释
	COMMENT=`$CMD -e "select table_comment from information_schema.TABLES i where i.TABLE_SCHEMA='$DB' AND i.TABLE_NAME ='$TABLE'" | tail -1`
	# 取字段信息
	COLUMN_STR=$($CMD <<EOF
select \
(concat(COLUMN_NAME, case when COLUMN_KEY='PRI' then ' (主键)' else '' end)) as '字段',\
COLUMN_TYPE  as '类型',\
(case when IS_NULLABLE='YES' then '是' else '否' end) as '空',\
(case when COLUMN_DEFAULT is null then 'NULL' else COLUMN_DEFAULT end) as '默认',\
COLUMN_COMMENT as '注释'\
from information_schema.COLUMNS  as i where i.TABLE_SCHEMA='$DB' AND i.TABLE_NAME ='$TABLE' \
order by i.ORDINAL_POSITION asc
EOF
)

	# 输出表结构
	echo "<div>"
	echo "<h2>$TABLE</h2>"
	echo "表注释：$COMMENT<br><br>"

	echo "<table width=\"100%\" class=\"print\">"
	echo "$COLUMN_STR" | awk -F"\t" 'BEGIN{print "<tbody>"} { print "<tr>"; if(NR == 1) {print "<th width=50>"$1"</th><th width=80>"$2"</th><th width=40>"$3"</th><th width=70>"$4"</th><th width=1000>"$5"</th>";} else {print "<td>"$1"</td><td>"$2"</td><td>"$3"</td><td>"$4"</td><td>"$5"</td>";} print "</tr>";} END{print "</tbody>"}'
	echo "<table>"
	echo "</div>"
	# break

done

echo "</body></html>"


