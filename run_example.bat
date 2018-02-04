@echo off

rem 第1個例子：直接用req.txt (咔啦脆雞*2、原味蛋撻*2)
perl CPKing_KFC.pl

rem 第2個例子：使用req.txt (咔啦脆雞*2、原味蛋撻*2)
perl CPKing_KFC.pl req.txt

rem 第3個例子：使用req_5_2.txt (咔啦脆雞*5、原味蛋撻*2)
perl CPKing_KFC.pl req_5_2.txt

rem 第4個例子：使用req_5_2x.txt (咔啦脆雞*5、原味蛋撻*2、不要冰無糖茉莉綠茶(小))
perl CPKing_KFC.pl req_5_2x.txt

rem 第5個例子：使用req_8_3.txt (咔啦脆雞*8、經典玉米*3)
perl CPKing_KFC.pl req_8_3.txt

rem 第6個例子：使用req_merge.txt (咔啦脆雞*2、原味蛋撻*2、百事可樂(小)*1、玉米濃湯(小)。合併炸烤雞、合併冷飲)
perl CPKing_KFC.pl req_merge.txt

rem 第7個例子：使用req_driveway.txt 開車至取餐車道: (咔啦脆雞*2、原味蛋撻*2) 
perl CPKing_KFC.pl req_driveway.txt

rem 第8個例子：使用req_40043.txt (咔啦脆雞*2、原味蛋撻*1、香酥脆薯(小)*1、冰無糖茉莉綠茶(小)*1。合併炸烤雞、合併冷飲)
perl CPKing_KFC.pl req_40043.txt

