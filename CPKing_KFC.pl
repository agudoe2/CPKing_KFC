#!/usr/bin/perl

#
# CPKing_KFC
# 肯德基怎麼買最划算
#
# https://github.com/agudoe2/CPKing_KFC
#
# kfc_coupon google sheet (如有更新請回報)
# https://goo.gl/7dL6yy
#
# agudoe2@gmail.com
#

# 請注意！需求清單改放到 req.txt 了！

#use strict;
#use warnings;


my $coupon_txt = "kfc_coupon.txt";
my $output_html = "output.html";
my $stime = time;
my ($sec, $min, $hour, $d, $m, $y) = localtime(time);
#my $today_date= (1900+$y)*10000 + ($m+1)*100 + $d;
print ">> DEBUG 20190210 暫時排除過期日檢查：因為沒有更新csv結果僅供參考\n";
my $today_date= (2018)*10000 + (3)*100 + 9;
print ">> DEBUG 20190210 暫時排除過期日檢查：因為沒有更新csv結果僅供參考\n";
my $merge_words_chicken = "合併炸烤雞：咔啦脆雞(中辣)_或_上校薄脆雞_或_美式BBQ醬烤煙燻雞";
my $merge_words_coketea = "合併冷飲：百事可樂_或_冰紅茶_或_冰無糖茉莉綠茶";
my $merge_words_warning = "請注意！可能依不同分店或不同優惠券而有不同結果！不一定可互換成功！";
my $driveway_enable_words = "經由KFC點餐車道";
my $need_set_words = "KFC加購";
my $driveway_words = "KFC點餐車道VIP加購";

print "\n";
print "用法： perl CPKing_KFC.pl [需求表。沒提供的話直接用req.txt]\n";
print "例子1：perl CPKing_KFC.pl\n";
print "例子2：perl CPKing_KFC.pl req.txt\n";
print "例子3：perl CPKing_KFC.pl req_8_3.txt\n";
print "\n";


# 讀取價格資料表 kfc_coupon.csv
my $csv_file = "kfc_coupon.csv";
die "錯誤！找不到 $csv_file 這個檔案\n" if( ! -e $csv_file );
open(FIN, "<$csv_file") || die "錯誤！開啟 $csv_file 過程發生錯誤";

my $coupon_idx = 0;
my $coupon_max = 0;
my $first_item = "咔啦脆雞(中辣)";
my $item_1st_loc;
my $item_max;
my @item_name;
my @reqitem_cur;
my $accu_set = 0; #累積套餐數 -> 算加價購
my $cost_cur = 0;
my $log_capacity = 10; #比較保留前n低的組合
my @log_pool;


my $need_set_cnt = 0;
my $csv_line = 0;
while(my $inbuf = <FIN>) {
    $csv_line++;
    #fix: 錯誤！找不到玉米濃湯(小) 這品項
    #https://github.com/agudoe2/CPKing_KFC/issues/1
    #chomp $inbuf;
    $inbuf =~ s/\r?\n$//;

    #非空白列
    next if( $inbuf =~ /^\s*$/ );
    #非注釋列
    next if( $inbuf =~ /^#/ );

    if( $item_loc{'優惠代碼'} > 0 ) {
        my @tmp = split /,/, $inbuf;

        #這些欄不能空白
        next if( $tmp[$item_loc{'名稱'}] =~ /^\s*$/ );
        next if( $tmp[$item_loc{'優惠價'}] =~ /^\s*$/ );
        next if( &expired( $tmp[$item_loc{'有效期間'}] ) );

        if( $tmp[$item_loc{'名稱'}] =~ /$need_set_words/ ) {
            $need_set_cnt++;
            $coupon_set[$coupon_idx] = -1;
        } elsif( $tmp[$item_loc{'名稱'}] =~ /$driveway_words/ ) {
            $driveway_only[$coupon_idx] = 1;
        } elsif( $tmp[$item_loc{'優惠代碼'}] eq "套餐" ) {
            $coupon_set[$coupon_idx] = 1;
            die "發生錯誤！$csv_file第$csv_line行：搭配餐後又出現套餐 (要調整順序：先列出所有套餐才能出現$need_set_words)\n" if( $need_set_cnt>0 );
        } else {
            $coupon_set[$coupon_idx] = 0;
        }

        for(my $i=0; $i< @tmp; $i++) {
            $coupon[$coupon_idx][$i] = $tmp[$i];
        }
        $coupon_idx++;
    } elsif( $inbuf =~ /^名稱/ ) {
        @item_name = split /,/, $inbuf;
        $item_max = @item_name;

        for(my $i=0; $i< $item_max; $i++) {
            $item_loc{ $item_name[$i] } = $i;
        }

        #一定要有的欄位
        next if($item_loc{$first_item} == 0);
        next if($item_loc{'優惠價'} == 0);
        #next if($item_loc{'咔啦脆雞(中辣)'} == 0);
        next if($item_loc{'原味蛋撻'} == 0);

        $item_1st_loc = $item_loc{$first_item};


        #處理單價列 20171211
        $ori_price_line = <FIN>;
        $ori_price_line =~ s/\r?\n$//;
    } elsif( $inbuf =~ /^上次更新/ ) {
        my @tmp = split /,/, $inbuf;
        $csv_ver = $tmp[1];
    }
}
close(FIN);
die "錯誤！$csv_file沒出現 $need_set_words" if( $need_set_cnt==0 );


#單價列放最後才能補小細縫
my @ori_price_tmp = split /,/, $ori_price_line;
for(my $i=$item_1st_loc; $i<$item_max; $i++) {
    next if($item_name[$i]=~/下架/);
    $coupon[$coupon_idx][$item_loc{'名稱'}] = $item_name[$i];
    $coupon[$coupon_idx][$item_loc{'優惠代碼'}] = "單點";
    $coupon[$coupon_idx][$item_loc{'連結'}] = "na";
    $coupon[$coupon_idx][$item_loc{'有效期間'}] = "na";
    $coupon[$coupon_idx][$item_loc{'原價'}] = $ori_price_tmp[$i];
    $coupon[$coupon_idx][$item_loc{'優惠價'}] = $ori_price_tmp[$i];
    $coupon[$coupon_idx][$i] = 1;
    $ori_price{$item_name[$i]} = $ori_price_tmp[$i];
    $coupon_idx++;
}
$coupon_max = $coupon_idx;


#合併後的內容另存
for(my $i=0; $i<$coupon_max; $i++) {
    for(my $j=0; $j<$item_max; $j++) {
        $coupon_merge[$i][$j] = $coupon[$i][$j];
    }
    $coupon_merge_price[$i] = $coupon_merge[$i][$item_loc{'優惠價'}]; #加速
}


#印出所有優惠券內容
my $coupon_html = "";
$coupon_html .= "<h3>相關優惠 (含線上優惠券)</h3>\n";
$coupon_html .= "<table border=1>\n";
$coupon_html .= "<tr><th>優惠代碼*</th><th>名稱</th><th>優惠價\$</th><th>有效期限</th><th>內容</th></tr>\n";

open(FOUT, ">$coupon_txt") || die "錯誤！無法寫出所有優惠券內容到 $coupon_txt";
print FOUT "#資料來源：https://goo.gl/7dL6yy\n";
print FOUT "#版本：$csv_ver\n\n";
for(my $i=0; $i<$coupon_idx; $i++) {
    my $code_tmp = $coupon[$i][$item_loc{'優惠代碼'}];
    my $name_tmp = $coupon[$i][$item_loc{'名稱'}];
    my $price_tmp = $coupon[$i][$item_loc{'優惠價'}];
    print FOUT "[$code_tmp] $name_tmp \$$price_tmp";

    my $vdate = $coupon[$i][$item_loc{'有效期間'}];
    print FOUT "  有效期間：$vdate" if( $vdate =~ /\// );
    print FOUT "\n";

    my $contain_tmp = &list_cnt( $i );
    print FOUT "-> $contain_tmp\n";

    my $link = $coupon[$i][$item_loc{'連結'}];
    print FOUT "$link\n" if( $link =~ /http/ );
    print FOUT "\n";

    $code_tmp = "<a href=$link target=_blank>$code_tmp</a>" if( $link =~ /http/ );
    $contain_tmp =~ s/、/<br>/g;
    #valign=top這樣超連結跳過來時才可以看到後面所有
    $coupon_html .= "<tr><td valign=top><a name=\"coupon$i\">$code_tmp</a></td><td valign=top>$name_tmp</td><td valign=top>$price_tmp</td><td valign=top>$vdate</td><td valign=top>$contain_tmp</td></tr>\n";
}
$coupon_html .= "</table>\n";
$coupon_html .= "<font color=blue>*點擊優惠代碼以查看線上優惠券</font><br>\n";
$coupon_html .= "<p>\n";
$coupon_html .= "\n";

close(FOUT);


# 讀取需求檔 reqXXX.txt
my $req_file = $ARGV[0];
$req_file = "req.txt" if( $req_file eq "" );
die "錯誤！需求表檔名必須是req開頭。例如req8_3.txt" if( $req_file !~ /^req.*/ );
die "錯誤！找不到 $req_file 這個檔案\n" if( ! -e $req_file );

open(FIN, "<$req_file") || die "錯誤！開啟 $req_file 過程發生錯誤";
my $line = 0;
my $driveway_enable = 0;
while(my $inbuf = <FIN>) {
    $line++;
    next if($inbuf =~ /^#/);
    next if($inbuf =~ /^\s*$/);
    #chomp $inbuf;
    $inbuf =~ s/\r?\n$//;
    my @tmp = split /\s+/, $inbuf;
    next if( $tmp[0] == 0 );

    if( $tmp[1] =~ /^合併/ ) {
        if( $tmp[1] eq $merge_words_chicken ) {
            $merge_chicken = 1;
        } elsif( $tmp[1] eq $merge_words_coketea) {
            $merge_coketea = 1;
        } else {
            die "$req_file第$line行錯誤！錯誤的合併選項";
        }
        next;
    } elsif( $tmp[1] eq $driveway_enable_words) {
        $driveway_enable = 1;
        next;
    }

    my $tmp_loc = $item_loc{$tmp[1]};
    die "$req_file第$line行錯誤！找不到 $tmp[1] 這品項" if( $tmp_loc < $item_1st_loc);
    $reqitem_cur[ $tmp_loc ] = $tmp[0];
}
close( FIN );


open(FHTML, ">$output_html") || die "錯誤！開啟 $output_html 過程發生錯誤";
print FHTML "日期時間：".localtime()."<br>\n";
print FHTML "價格資料表版本：$csv_ver<br>\n";
print FHTML "<h3>需求清單</h3>\n";
print FHTML "<table border=1>\n";
print FHTML "<tr><th>品項</th><th>數量</th><th>單價\$</th><th>金額\$</th></tr>\n";

print "日期時間：".localtime()."\n";
print "價格資料表版本：$csv_ver\n";
print "\n";
print "需求清單: (需求表檔名：$req_file)\n";
print "-------------------------\n";
my $ori_price_total = 0;
my $ori_cnt = 0;

for(my $i=0; $i<@reqitem_cur; $i++) {
    next if($reqitem_cur[$i]==0);
    if($reqitem_cur[$i]<0) {
        print "不要$item_name[$i]\n";
    } else {
        my $ssum = $ori_price{$item_name[$i]}*$reqitem_cur[$i];
        print "$reqitem_cur[$i]*$item_name[$i] (單價:\$$ori_price{$item_name[$i]})\n";
        print FHTML "<tr><td>$item_name[$i]</td><td>$reqitem_cur[$i]</td><td>$ori_price{$item_name[$i]}</td><td>$ssum</td></tr>\n";
        $ori_price_total += $ssum;
        $ori_cnt += $reqitem_cur[$i];
    }
}#
print "-------------------------\n";
print "單點總價: \$$ori_price_total\n";
print "\n";
print "\n";

print FHTML "<tr><td><b>總計</b></td><td><b>$ori_cnt</b></td><td><b></b></td><td><b>$ori_price_total</b></td></tr>\n";
print FHTML "</table>\n";
print FHTML "<p>\n";
print FHTML "\n";

#初始化前n低的價格，用來比較前log_capacity低的組合
for(my $i=0; $i<=$log_capacity; $i++) {
    $log_pool[$i] = $ori_price_total;
}


my $real_merge = 0;

#處理合併炸烤雞。合併後價錢設定為咔啦脆雞(中辣)
if( $merge_chicken ) {
    my @tmp_2bmerge = qw/咔啦脆雞(中辣) 上校薄脆雞 美式BBQ醬烤煙燻雞/;
    my $cnt_merged = 0;

    #合併需求
    for( my $i=0; $i< @tmp_2bmerge; $i++ ) {
        my $tmp_loc = $item_loc{ $tmp_2bmerge[$i] };
        die "錯誤！找不到 $tmp_2bmerge[$i] 這品項" if( $tmp_loc < $item_1st_loc);
        $cnt_merged += $reqitem_cur[ $tmp_loc ];
        $reqitem_cur[ $tmp_loc ] = 0;
    }

    #若合併後>0才繼續做下一步
    if( $cnt_merged > 0 ) {
        $reqitem_cur[$item_max]=$cnt_merged;
        for(my $c=0; $c<$coupon_max; $c++) {
            for( my $i=0; $i< @tmp_2bmerge; $i++ ) {
                my $tmp_loc = $item_loc{ $tmp_2bmerge[$i] };
                die "錯誤！找不到 $tmp_2bmerge[$i] 這品項" if( $tmp_loc < $item_1st_loc);
                if( $coupon_merge[$c][ $tmp_loc ] < 0 ) { # 不要這項
                    $coupon_merge[$c][ $item_max ] = -1;
                } elsif( $coupon_merge[$c][ $item_max ] >= 0 ) {
                    $coupon_merge[$c][ $item_max ] += $coupon_merge[$c][ $tmp_loc ]; # 轉移到合併項
                }
                $coupon_merge[$c][ $tmp_loc ] = 0; # 清掉舊的
            }
        }
        $item_name[$item_max] = $merge_words_chicken;
        $item_name[$item_max] =~ s/：.*//;
        $ori_price{$item_name[$item_max]} = $ori_price{'咔啦脆雞(中辣)'};
        $item_max++;
        $real_merge++;
    }
}

#處理合併冷飲。合併後價錢設定為百事可樂(小)
if( $merge_coketea ) {
    my @tmp_2bmerge = qw/冰無糖茉莉綠茶 冰紅茶 百事可樂/;
    my $cnt_merged = 0;

    #合併需求 (寫法跟炸烤雞不一樣因為冷飲有大中小兒杯)
    for( my $i=0; $i< @tmp_2bmerge; $i++ ) {
        for(my $j=$item_1st_loc; $j<$item_max; $j++) {
            if( $item_name[$j] =~ /^$tmp_2bmerge[$i]/ ) {
                $cnt_merged += $reqitem_cur[ $j ];
                $reqitem_cur[ $j ] = 0;
            }
        }
    }

    #若合併後>0才繼續做下一步
    if( $cnt_merged > 0 ) {
        $reqitem_cur[$item_max]=$cnt_merged;
        for(my $c=0; $c<$coupon_max; $c++) {
            for( my $i=0; $i< @tmp_2bmerge; $i++ ) {
                for(my $j=$item_1st_loc; $j<$item_max; $j++) {
                    if( $item_name[$j] =~ /^$tmp_2bmerge[$i]/ ) {
                        if( $coupon_merge[$c][ $j ] < 0 ) { # 不要這項
                            $coupon_merge[$c][ $item_max ] = -1;
                        } elsif( $coupon_merge[$c][ $item_max ] >= 0 ) {
                            $coupon_merge[$c][ $item_max ] += $coupon_merge[$c][ $j ]; # 轉移到合併項
                        }
                        $coupon_merge[$c][ $j ] = 0; # 清掉舊的
                    }
                }
            }
        }
        $item_name[$item_max] = $merge_words_coketea;
        $item_name[$item_max] =~ s/：.*//;
        $ori_price{$item_name[$item_max]} = $ori_price{'百事可樂(小)'};
        $item_max++;
        $real_merge++;
    }
}

#真的有合併的話，合併後的需求清單
if( $real_merge ) {
    print FHTML "<h3>合併後需求清單</h3>\n";
    print FHTML "<table border=1>\n";
    print FHTML "<tr><th>品項</th><th>數量</th></tr>\n";
    
    print "合併後需求清單:\n";
    print "-------------------------\n";
    my $ori_cnt = 0;
    for(my $i=0; $i<@reqitem_cur; $i++) {
        next if($reqitem_cur[$i]==0);
        if($reqitem_cur[$i]<0) {
            print "不要$item_name[$i]\n";
        } else {
            print "$reqitem_cur[$i]*$item_name[$i]\n";
            print FHTML "<tr><td>$item_name[$i]</td><td>$reqitem_cur[$i]</td></tr>\n";
            $ori_cnt += $reqitem_cur[$i];
        }
    }#
    print "-------------------------\n";
    print "$merge_words_warning\n";
    print "$merge_words_chicken\n" if( $merge_chicken );
    print "$merge_words_coketea\n" if( $merge_coketea );
    
    print FHTML "<tr><td><b>總計</b></td><td><b>$ori_cnt</b></td></tr>\n";
    print FHTML "</table>\n";
    print FHTML "<font color=red>$merge_words_warning</font><br>\n";
    print FHTML "$merge_words_chicken<br>\n" if( $merge_chicken );
    print FHTML "$merge_words_coketea<br>\n" if( $merge_coketea );
    print FHTML "<p>\n";
    print FHTML "\n";
}

if( $driveway_enable ) {
    print "$driveway_enable_words\n";
    print FHTML "$driveway_enable_words<br>\n";
} else {
    print "不是經由KFC點餐車道\n";
    print FHTML "不是經由KFC點餐車道<br>\n";
}

my @dont_want = ();
my $reqitem2_gold = 0;
my $reqitem2_now = 0;
my $reqitem2_typ = 0;
my $reqitem2_cnt = 0;
my $reqitem2_maxcnt = 8; # 64bit/8
# 把 reqitem_cur 轉成 reqitem2_XXX
for(my $i=0; $i<@reqitem_cur; $i++) {
    if($reqitem_cur[$i]==0) {
        # next;
    } elsif( $reqitem_cur[$i]<0 ) { #不要xxx，掃一遍所有coupon把有xxx的拿掉
        push @dont_want, $i;
        # next;
    } else { # $reqitem_cur[$i]>0
        if( $reqitem2_cnt<$reqitem2_maxcnt ) {
            $reqitem2_gold <<= 8;
            $reqitem2_gold |= $reqitem_cur[$i];
            $reqitem2_typ <<= 8;
            $reqitem2_typ |= $i;
            $reqitem2_cnt++;
        } else {
            print "警告！要計算的品項超過上限reqitem_maxcnt($reqitem2_maxcnt)，先忽略$tmp[1]需要$reqitem_cur[$i]個\n";
            # next;
        }
    }
}

# 建立coupon2_merge (只保留要求，加速計算)
my @coupon2_merge = ();
for(my $i=0; $i<$reqitem2_cnt; $i++) {
    my $this_typ = ($reqitem2_typ>>(8*($reqitem2_cnt-1-$i))) & 0xff;
    for(my $j=0; $j<$coupon_max; $j++) {
        $coupon2_merge[$j] <<= 8;
        $coupon2_merge[$j] |= $coupon_merge[$j][$this_typ];
    }
}

# 如果不要某項，就把對應的coupon2_merge丟掉
foreach my $i (@dont_want) {
    for(my $j=0; $j<$coupon_max; $j++) {
        $coupon2_merge[$j] = 0 if( $coupon_merge[$j][$i] > 0 );
    }
}

#主要計算
&compute_loop(0);
#算完了

#依價錢排序
for( my $i=0; $i<$coupon_save_cnt; $i++) {
    $coupon_save_sort[$i] = $i;

    for(my $j=0; $j<$coupon_max; $j++) {
        $coupon_used[$j] = $coupon_saved[$i][$j];
    }
    $addition_save[$i] = &list_cnt(-2);
    $addition_value_save[$i] = $addition_value;
}
for(my $i=0; $i<$coupon_save_cnt-1; $i++) {
    for(my $j=$i+1; $j<$coupon_save_cnt; $j++) {
        if( $cost_save[$coupon_save_sort[$i]] > $cost_save[$coupon_save_sort[$j]] ||
            ($cost_save[$coupon_save_sort[$i]] == $cost_save[$coupon_save_sort[$j]] && $addition_value_save[$coupon_save_sort[$i]]<$addition_value_save[$coupon_save_sort[$j]])
        ) {
            my $tmp = $coupon_save_sort[$i];
            $coupon_save_sort[$i] = $coupon_save_sort[$j];
            $coupon_save_sort[$j] = $tmp;
        }
    }
}

#印出排序結果
print FHTML "<h3>計算結果 (含線上優惠券)</h3>\n";
print FHTML "<table border=1>\n";
print FHTML "<tr><th>排名</th><th>總價\$</th><th>省下\$</th><th>組合*</th><th>多了</th><th>多了\$</th></tr>\n";

print "\n\n\n";
my $double_cost_bound = $cost_save[$coupon_save_sort[0]]*2;
my $ignore = "";
for(my $i=0; $i<$coupon_save_cnt; $i++) {
    my $i_sort = $coupon_save_sort[$i];
    my $this_cost = $cost_save[$i_sort];
    if($this_cost > $double_cost_bound) {
        $ignore = "..忽略其他 ".($coupon_save_cnt-$i)." 比2倍單點價還貴的組合";
        print "$ignore\n";
        last;
    }
    if($this_cost > $ori_price_total) {
        $ignore = "..忽略其他 ".($coupon_save_cnt-$i)." 比單點總價還貴的組合";
        print "$ignore\n";
        last;
    }
    if( $i>=$log_capacity ) {
        $ignore = "..為了加速，只看最便宜的 $log_capacity 組，其他 ".($coupon_save_cnt-$i)." 組省略";
        print "$ignore\n";
        last;
    }


    my $coupon_detail = "";
    my $coupon_simple = "";
    for(my $j=0; $j<$coupon_max; $j++) {
        my $used_coupon_cnt = $coupon_saved[$i_sort][$j];
        $coupon_used[$j] = $used_coupon_cnt;
        next if($used_coupon_cnt ==0 );
        my $code_tmp = $coupon_merge[$j][$item_loc{'優惠代碼'}];
        my $link = $coupon_merge[$j][$item_loc{'連結'}];
        $coupon_detail .= "[$code_tmp]*$used_coupon_cnt $coupon_merge[$j][$item_loc{'名稱'}] \$$coupon_merge_price[$j] -> ".&list_cnt( $j )."\n";
        $code_tmp = "<a href=$link target=_blank>$code_tmp</a>" if( $link =~ /http/ );
        $coupon_simple .= "[$code_tmp]*$used_coupon_cnt <a href=#coupon$j>$coupon_merge[$j][$item_loc{'名稱'}]</a> \$$coupon_merge_price[$j]<br>";
    }

    my $i1 = $i+1;
    my $diff = $ori_price_total-$cost_save[$i_sort];
    print "#$i1 總價: \$$cost_save[$i_sort] -> ".&list_cnt(-1)."\n";
    print $coupon_detail;
    print "☆便宜\$$diff";

    my $addition = $addition_save[$i_sort];
    my $addition_value = $addition_value_save[$i_sort];
    print "(+$addition_value=".($ori_price_total-$cost_save[$i_sort]+$addition_value).")，還多了：$addition" if($addition ne "");
    print "\n\n";

    $addition =~ s/、/<br>/g;
    $addition_value = "" if( $addition_value == 0 );
    print FHTML "<tr><td>$i1</td><td>$cost_save[$i_sort]</td><td>$diff</td><td>$coupon_simple</td><td>$addition</td><td>$addition_value</td></tr>\n";
}
print FHTML "</table>\n";
print FHTML "<font color=blue>*點擊優惠代碼以查看線上優惠券</font><br>\n";
print FHTML "$ignore\n" if( $ignore ne "");
print FHTML "<p>\n";
print FHTML "\n";

print FHTML $coupon_html;

close(FHTML);

my $etime = time;

print "\n";
print "計算時間".($etime-$stime)."秒\n";
print "已產生優惠券內容：$coupon_txt\n";
print "已產生結果網頁：$output_html\n";

print ">> DEBUG 20190210 暫時排除過期日檢查：因為沒有更新csv結果僅供參考\n";

exit;

#遞迴計算主要function
sub compute_loop {
    my $level = $_[0];
    my $reqitem2_bak = $reqitem2_now;
    my $cost_bak = $cost_cur;

    #計算最多幾組
    my $range_max=0;
    if( $driveway_only[$level] && ($driveway_coupon_used || !$driveway_enable) ) {
        #點餐車道VIP coupon
        #   用過 或是 不是經由KFC點餐車道
    } elsif( $coupon2_merge[$level] == 0 ) {
        #出現不要的食物 或 沒符合需求
    } else {
        my $coupon2_merge_level = $coupon2_merge[$level];
        my $reqitem2_gold_this = $reqitem2_gold;
        my $reqitem2_now_this = $reqitem2_now;
        for(my $i=0; $i<$reqitem2_cnt; $i++) {
            my $this = $coupon2_merge_level & 0xff;
            my $gold_this = $reqitem2_gold_this & 0xff;
            my $now_this = $reqitem2_now_this & 0xff;
            if( $this>0 && $gold_this>$now_this ) {
                my $range_this = int( ($gold_this - $now_this)/$this );
                $range_this++ if( $gold_this-$now_this > $range_this*$this ); #非整除

                #需要搭配套餐 而且 套餐數不夠用 --> 減少挑配餐
                if( $coupon_set[$level]<0 && $range_this > $accu_set ) {
                    $range_this = $accu_set;
                }

                $range_max = $range_this if( $range_max < $range_this );
                $range_max = 1 if( $driveway_only[$level] ); #點餐車道vip只能用一張
            }
            $coupon2_merge_level >>= 8;
            $reqitem2_gold_this >>= 8;
            $reqitem2_now_this >>= 8;
        }
    }

    # 0組
    &compute_loop( $level+1 ) if($level<$coupon_max);

    for(my $i=1; $i<=$range_max; $i++) {
        my $cost_tmp = $cost_bak + $coupon_merge_price[$level]*$i;
        if( $cost_tmp>$ori_price_total || $cost_tmp>$log_pool[$log_capacity] ) {
            #print "DEBUG: price $cost_tmp>$ori_price_total || $cost_tmp>$log_pool[$log_capacity]\n";
            last; #已經太貴了，之後就不用試了
        }

        $coupon_used[$level] = $i;
        $reqitem2_now = $reqitem2_bak + $coupon2_merge[$level]*$i;

        $type_used++ if($i>0);
        $driveway_coupon_used++ if($driveway_only[$level] && $i>0 );
        my $all_bought_tried = 0;
        if($i>0 && $i==$range_max ) { # 只有在滿max才需要算是否全買完
            #print "DEBUG meet!\n";
            $all_bought_tried = &all_bought;
            if( $all_bought_tried && !($type_used<2 && $driveway_coupon_used) ) { #車道vip有其他消費==>不是只有車道消費
                for(my $j=0; $j<$coupon_max; $j++) {
                    $coupon_saved[$coupon_save_cnt][$j] = $coupon_used[$j];
                    #next if( $coupon_used[$j]==0 );
                    #print "DEBUG: [$coupon_merge[$j][$item_loc{'優惠代碼'}]] $coupon_merge[$j][$item_loc{'名稱'}] \$$coupon_merge[$j][$item_loc{'優惠價'}] * $coupon_used[$j]\n";
                }
    
                $cost_save[$coupon_save_cnt] = $cost_tmp;
                $coupon_save_cnt++;
    
                #減少時間：只算前幾個便宜的
                #push @log_pool, $cost_tmp;
                if( $log_pool[$log_capacity]>$cost_tmp ) {
                    $log_pool[$log_capacity]=$cost_tmp;
                    @log_pool = sort {$a <=> $b} @log_pool;
                }
            }
        }

        if( !$all_bought_tried && $level<$coupon_max ) {
            $accu_set += $coupon_set[$level]*$i;
            $cost_cur = $cost_tmp;
            &compute_loop( $level+1 );
            $cost_cur = $cost_bak;
            $accu_set -= $coupon_set[$level]*$i;
        }
        ###
        $driveway_coupon_used-- if($driveway_only[$level] && $i>0 );
        $type_used-- if($i>0);

        $reqitem2_now = $reqitem2_bak;
        $coupon_used[$level] = 0;
    }
}

#提供各產品細項
#list_cnt(x)
#x>=0: 第x項coupon券的內容
#x=-1: 所有已使用coupon券的品項組合
#x=-2: 所有已使用coupon券的品項組合-需求清單
sub list_cnt {
    my $specific_coupon = $_[0];
    my $first = 1;
    my $ret = "";
    $addition_value=0;

    for(my $i=$item_1st_loc; $i<$item_max; $i++) {
        my $cnt=0;
        if( $specific_coupon < 0 ) {
            for(my $j=0; $j<$coupon_max; $j++) {
                $cnt += $coupon_merge[$j][$i]*$coupon_used[$j];
            }
            $cnt-=$reqitem_cur[$i] if($specific_coupon<-1 && $reqitem_cur[$i]>0);
        } else { #單獨的coupon內容就用合併前的coupon
            my $tmp = $coupon[$specific_coupon][$i];
            $tmp = -$tmp if( $tmp<0 );
            $cnt += $tmp;
        }

        if( $cnt>0 ) {
            if($first) {
                $first=0;
            } else {
                $ret .= "、";
            }
            $ret .= "$item_name[$i]*$cnt";
            $addition_value += $ori_price{$item_name[$i]}*$cnt;
        }
    }
    return $ret;
}

#是否已過期
sub expired {
    my $vdate = $_[0];
    my $expired = 0;
    if( $vdate =~ /\//) {
        my @tmp_date = split /\//, $vdate;
        $expired++ if( $tmp_date[0]*10000 + $tmp_date[1]*100 + $tmp_date[2] < $today_date );
    }
    #print "DEBUG: ($vdate) $today_date $expired\n";
    return $expired;
}

#是否已買齊
sub all_bought {
    my $gold=$reqitem2_gold;
    my $now=$reqitem2_now;
    for(my $i=0; $i<$reqitem2_cnt; $i++) {
        return 0 if( ($gold&0xff) > ($now&0xff) );
        $gold>>=8;
        $now>>=8;
    }
    return 1;
}
