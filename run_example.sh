#!/bin/sh

#第1個例子：直接用req.txt (咔啦脆雞*2、原味蛋撻*2)
perl CPKing_KFC.pl

#第2個例子：使用req.txt (咔啦脆雞*2、原味蛋撻*2)
perl CPKing_KFC.pl req.txt | tee run.log

#第3個例子：使用req_5_2.txt (咔啦脆雞*5、原味蛋撻*2)
perl CPKing_KFC.pl req_5_2.txt | tee run_5_2.log

#第4個例子：使用req_5_2x.txt (咔啦脆雞*5、原味蛋撻*2、不要冰無糖茉莉綠茶(小))
perl CPKing_KFC.pl req_5_2x.txt | tee run_5_2x.log

#第5個例子：使用req_8_3.txt (咔啦脆雞*8、經典玉米*3)
perl CPKing_KFC.pl req_8_3.txt | tee run_8_3.log

#第6個例子：使用req_merge.txt (咔啦脆雞*2、原味蛋撻*2、百事可樂(小)*1、玉米濃湯(小)。合併炸烤雞、合併冷飲)
perl CPKing_KFC.pl req_merge.txt | tee run_merge.log

# 第7個例子：使用req_driveway.txt 開車至取餐車道: (咔啦脆雞*2、原味蛋撻*2) 
perl CPKing_KFC.pl req_driveway.txt | tee run_driveway.log

#第8個例子：使用req_40043.txt (咔啦脆雞*2、原味蛋撻*1、香酥脆薯(小)*1、冰無糖茉莉綠茶(小)*1。合併炸烤雞、合併冷飲)
perl CPKing_KFC.pl req_40043.txt | tee run_40043.log

