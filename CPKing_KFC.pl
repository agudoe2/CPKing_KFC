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


my $coupon_txt = "kfc_coupon.txt";
my $stime = time;
my ($sec, $min, $hour, $d, $m, $y) = localtime(time);
my $today_date= (1900+$y)*10000 + ($m+1)*100 + $d;

print "\n";
print "用法： perl CPKing_KFC.pl [需求表。沒提供的話直接用req.txt]\n";
print "例子1：prel CPKing_KFC.pl\n";
print "例子2：prel CPKing_KFC.pl req.txt\n";
print "例子3：prel CPKing_KFC.pl req_8_3.txt\n";
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
my $cost_cur = 0;
my $log_capacity = 10;
my @log_pool;


while(my $inbuf = <FIN>) {
    chomp $inbuf;

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

        #print "DEBUG: $coupon_idx : $inbuf\n";
        for(my $i=0; $i< @tmp; $i++) {
            $coupon[$coupon_idx][$i] = $tmp[$i];
        }
        $coupon_idx++;
    } elsif( $inbuf =~ /^名稱/ ) {
        @item_name = split /,/, $inbuf;
        $item_max = @item_name;
        for(my $i=0; $i< @item_name; $i++) {
            $item_loc{ $item_name[$i] } = $i;
            #print "DEBUG: item_log { $item_name[$i] } = $i\n";
        }

        #一定要有的欄位
        next if($item_loc{$first_item} == 0);
        next if($item_loc{'優惠價'} == 0);
        #next if($item_loc{'咔啦脆雞(中辣)'} == 0);
        next if($item_loc{'原味蛋撻'} == 0);

        $item_1st_loc = $item_loc{$first_item};


        #處理單價列 20171211
        $ori_price_line = <FIN>;
    } elsif( $inbuf =~ /^上次更新/ ) {
        my @tmp = split /,/, $inbuf;
        $csv_ver = $tmp[1];
    }
}

#印出所有優惠券內容
open(FOUT, ">$coupon_txt") || die "錯誤！無法寫出所有優惠券內容到 $coupon_txt";
print FOUT "#資料來源：https://goo.gl/7dL6yy\n";
print FOUT "#版本：$csv_ver\n\n";
for(my $i=0; $i<$coupon_idx; $i++) {
    print FOUT "[$coupon[$i][$item_loc{'優惠代碼'}]] $coupon[$i][$item_loc{'名稱'}] \$$coupon[$i][$item_loc{'優惠價'}]";

    my $vdate = $coupon[$i][$item_loc{'有效期間'}];
    print FOUT "  有效期間：$vdate" if( $vdate =~ /\// );
    print FOUT "\n";

    print FOUT "-> ".&list_cnt( $i )."\n";

    my $link = $coupon[$i][$item_loc{'連結'}];
    print FOUT "$link\n" if( $link =~ /http/ );
    print FOUT "\n";
}
close(FOUT);

#單價列放最後才能補小細縫
my @ori_price_tmp = split /,/, $ori_price_line;
for(my $i=$item_1st_loc; $i<@item_name; $i++) {
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
#print "DEBUG: coupon_max = $coupon_max\n";
#print "DEBUG: \n";
close(FIN);


# 讀取需求檔 reqXXX.txt
my $req_file = $ARGV[0];
$req_file = "req.txt" if( $req_file eq "" );
die "錯誤！需求表檔名必須是req開頭。例如req8_3.txt" if( $req_file !~ /^req.*/ );
die "錯誤！找不到 $req_file 這個檔案\n" if( ! -e $req_file );

open(FIN, "<$req_file") || die "錯誤！開啟 $req_file 過程發生錯誤";
my $line = 0;
while(my $inbuf = <FIN>) {
    $line++;
    next if($inbuf =~ /^#/);
    chomp $inbuf;
    my @tmp = split /\s+/, $inbuf;
    next if( $tmp[0] == 0 );
    my $tmp_loc = $item_loc{$tmp[1]};
    die "$req_file第$line錯誤！找不到 $tmp[1] 這品項" if( $tmp_loc < $item_1st_loc);
    $reqitem_cur[ $tmp_loc ] = $tmp[0];
}
close( FIN );


print "目前日期時間：".localtime()."\n";
print "價格資料表版本：$csv_ver\n";
print "\n";
print "需求清單: (需求表檔名：$req_file)\n";
print "-------------------------\n";
my $ori_price_total = 0;
for(my $i=0; $i<@reqitem_cur; $i++) {
    next if($reqitem_cur[$i]==0);
    if($reqitem_cur[$i]<0) {
        print "不要$item_name[$i]\n";
    } else {
        for(my $j=0; $j<@coupon; $j++) {
        }
        print "$reqitem_cur[$i]*$item_name[$i] (單點原價:\$$ori_price{$item_name[$i]})\n";
        $ori_price_total += $ori_price{$item_name[$i]}*$reqitem_cur[$i];
    }
}#
print "-------------------------\n";
print "單點總價: \$$ori_price_total\n";
print "\n";

#初始化前n低的價格
for(my $i=0; $i<$log_capacity+1; $i++) {
    $log_pool[$i] = $ori_price_total;
}

#主要計算
&compute_loop(0);
#算完了

#依價錢排序
for( my $i=0; $i<$coupon_save_cnt; $i++) {
    $coupon_save_sort[$i] = $i;
}
for(my $i=0; $i<$coupon_save_cnt-1; $i++) {
    for(my $j=$i+1; $j<$coupon_save_cnt; $j++) {
        if($cost_save[$coupon_save_sort[$i]] > $cost_save[$coupon_save_sort[$j]]) {
            my $tmp = $coupon_save_sort[$i];
            $coupon_save_sort[$i] = $coupon_save_sort[$j];
            $coupon_save_sort[$j] = $tmp;
        }
    }
}

#印出排序結果
print "\n\n\n";
my $double_cost_bound = $cost_save[$coupon_save_sort[0]]*2;
for(my $i=0; $i<$coupon_save_cnt; $i++) {
    my $i_sort = $coupon_save_sort[$i];
    my $this_cost = $cost_save[$i_sort];
    if($this_cost > $double_cost_bound) {
        print "..忽略其他 ".($coupon_save_cnt-$i)." 比2倍單點價還貴的組合\n";
        last;
    }
    if($this_cost > $ori_price_total) {
        print "..忽略其他 ".($coupon_save_cnt-$i)." 比單點總價還貴的組合\n";
        last;
    }
    if( $i>=$log_capacity ) {
        print "..為了加速，只看最便宜的 $log_capacity 組，其他 ".($coupon_save_cnt-$i)." 組省略\n";
        last;
    }


    my $coupon_detail = "";
    for(my $j=0; $j<$coupon_max; $j++) {
        my $used_coupon_cnt = $coupon_saved[$i_sort][$j];
        $coupon_used[$j] = $used_coupon_cnt;
        next if($used_coupon_cnt ==0 );
        $coupon_detail .= "[$coupon[$j][$item_loc{'優惠代碼'}]]*$used_coupon_cnt $coupon[$j][$item_loc{'名稱'}] \$$coupon[$j][$item_loc{'優惠價'}] -> ".&list_cnt( $j )."\n";
    }

    my $i1 = $i+1;
    print "#$i1. Total price: \$$cost_save[$i_sort] -> ".&list_cnt(-1)."\n";
    print $coupon_detail;
    print "☆便宜\$".($ori_price_total-$cost_save[$i_sort]);
    my $addition = &list_cnt(-2);
    print "(+$addition_value=".($ori_price_total-$cost_save[$i_sort]+$addition_value).")，還多了：$addition" if($addition ne "");
    print "\n\n";
}

my $etime = time;

print "\n";
print "計算時間".($etime-$stime)."秒\n";
print "已產生優惠券內容：$coupon_txt\n";


exit;

#遞迴計算主要function
sub compute_loop {
    my $level = $_[0];
    my @reqitem_bak = @reqitem_cur;
    my $cost_bak = $cost_cur;
    #my @coupon_used;

    #print "\nDEBUG: level=$level ($coupon[$level][0]) / $coupon_max\n";

    if( $level == $coupon_max ) {
        #check first if getting everything?
        for($item_chk=$item_1st_loc; $item_chk<$item_max; $item_chk++) {
            last if( $reqitem_cur[$item_chk] > 0);
        }
        #print "DEBUG: last checked: $item_name[$item_
        if($item_chk==$item_max) {
            for(my $i=0; $i<$coupon_max; $i++) {
                next if( $coupon_used[$i]==0 );
                #print "DEBUG: [$coupon[$i][$item_loc{'優惠代碼'}]] $coupon[$i][$item_loc{'名稱'}] \$$coupon[$i][$item_loc{'優惠價'}] * $coupon_used[$i]\n";
                $coupon_saved[$coupon_save_cnt][$i] = $coupon_used[$i];
            }
            #print "DEBUG: Total price: \$$cost_cur -> ";
            $cost_save[$coupon_save_cnt] = $cost_cur;
            $coupon_save_cnt++;
            #print "DEBUG: ".&list_cnt(-1);
            #print "DEBUG: \n\n";

            # maintain price pool
            push @log_pool, $cost_cur;
            @log_pool = sort {$a <=> $b} @log_pool;
            #print "DEBUG: $cost_cur, $log_pool[$log_capacity]\n";
        }
        return;
    } else {
        #print "DEBUG: found range\n";
        my $range_max=0;
        for(my $i=$item_1st_loc; $i<$item_max; $i++) {
            next if($coupon[$level][$i]==0);
            if($reqitem_cur[$i]<0) {
                $range_max = 0;
                last;
            }
            my $range_this = ($reqitem_cur[$i]-($reqitem_cur[$i]%$coupon[$level][$i])) / $coupon[$level][$i];
            $range_this++ if( ($reqitem_cur[$i]%$coupon[$level][$i]) > 0);
            $range_max = $range_this if( $range_max < $range_this );
        }

        for(my $i=0; $i<=$range_max; $i++) {
            my $cost_tmp = $cost_bak + $coupon[$level][$item_loc{'優惠價'}]*$i;
            last if( $cost_tmp>$ori_price_total || $cost_tmp>$log_pool[$log_capacity] );

            $coupon_used[$level] = $i;
            for(my $j=$item_1st_loc; $j<$item_max; $j++) {
                $reqitem_cur[$j] -= $coupon[$level][$j]*$i;
            }
            $cost_cur = $cost_tmp;
            #print "DEBUG: $level/$coupon_max: ".(" "x$level)."$coupon[$level][$item_loc{'名稱'}] range = $i/$range_max\n";
            &compute_loop( $level+1 );
            @reqitem_cur = @reqitem_bak;
        }
        #print "DEBUG: done\n";
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
                $cnt += $coupon[$j][$i]*$coupon_used[$j];
            }
            $cnt-=$reqitem_cur[$i] if($specific_coupon<-1 && $reqitem_cur[$i]>0);
        } else {
            $cnt += $coupon[$specific_coupon][$i];
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
