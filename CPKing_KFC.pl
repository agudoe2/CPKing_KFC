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
# 2017/12/13
#

# 修改需求清單 (前面#代表可有可無。若需求<0代表不要這項)
#################################################
$req{'咔啦脆雞(中辣)'} = 8;
#$req{'上校薄脆雞'} = 1;
#$req{'美式BBQ醬烤煙燻雞'} = 1;
#$req{'醬香酸甜風味炸雞'} = 1;
#$req{'原味蛋撻'} = 2;
#$req{'蘭姆醺萄蛋撻'} = 1;
$req{'經典玉米'} = 3;
#$req{'上校雞塊'} = 1;
#$req{'雞汁風味飯'} = 1;
#$req{'義式香草紙包雞'} = 1;
#$req{'咔啦雞腿堡'} = 1;
#$req{'上校經典脆雞堡'} = 1;
#$req{'熱情森巴咔啦雞腿堡'} = 1;
#$req{'紐奧良烤雞腿堡'} = 1;
#$req{'紐奧良烤全雞'} = 1;
#$req{'香酥脆薯(大)'} = 1;
#$req{'香酥脆薯(中)'} = 1;
#$req{'香酥脆薯(小)'} = 1;
#$req{'勁爆雞米花(大)'} = 1;
#$req{'勁爆雞米花(小)'} = 1;
#$req{'香酥洋蔥圈'} = 1;
#$req{'川香椒麻烤翅(對)'} = 1;
#$req{'點心盒-勁爆雞米花+香酥脆薯(小)'} = 1;
#$req{'點心盒-上校雞塊+香酥脆薯(小)'} = 1;
#$req{'墨西哥莎莎霸王捲'} = 1;
#$req{'金黃脆腿條(對)'} = 1;
#$req{'草莓起司冰淇淋大福'} = 1;
#$req{'提拉米蘇冰淇淋大福'} = 1;
#$req{'鮮蔬沙拉(千島醬)'} = 1;
#$req{'100%柳橙汁320g'} = 1;
#$req{'百事可樂1.25L'} = 1;
#$req{'百事可樂(大)'} = 1;
#$req{'百事可樂(中)'} = 1;
#$req{'百事可樂(小)'} = 1;
#$req{'百事可樂(兒)'} = 1;
#$req{'冰紅茶(大)'} = 1;
#$req{'冰紅茶(中)'} = 1;
#$req{'冰紅茶(小)'} = 1;
#$req{'冰紅茶(兒)'} = 1;
#$req{'冰無糖茉莉綠茶(大)'} = 1;
#$req{'冰無糖茉莉綠茶(中)'} = 1;
$req{'冰無糖茉莉綠茶(小)'} = -1;
#$req{'冰無糖茉莉綠茶(兒)'} = 1;
#$req{'冰義式咖啡'} = 1;
#$req{'冰義式拿鐵'} = 1;
#$req{'經典冰奶茶(中)'} = 1;
#$req{'經典冰奶茶(小)'} = 1;
#$req{'經典熱奶茶(中)'} = 1;
#$req{'經典熱奶茶(小)'} = 1;
#$req{'七喜(大)'} = 1;
#$req{'七喜(中)'} = 1;
#$req{'七喜(小)'} = 1;
#$req{'七喜(兒)'} = 1;
#$req{'鮮奶(中)'} = 1;
#$req{'鮮奶(小)'} = 1;
#$req{'熱紅茶'} = 1;
#$req{'熱義式卡布奇諾'} = 1;
#$req{'熱義式拿鐵'} = 1;
#$req{'熱義式咖啡(大)'} = 1;
#$req{'熱義式咖啡(小)'} = 1;
#$req{'玉米濃湯(大)'} = 1;
#$req{'玉米濃湯(小)'} = 1;
#################################################


#my $ifile = "kfc_coupon.csv";
my $ifile = $ARGV[0];
die "usage: $0 <file.csv>\nex: $0 kfc_coupon.csv\n" if( $ifile eq "" );
die "ERROR! $ifile not found\n" if( ! -e $ifile );
open(FIN, "<$ifile") || die "ERROR! open $ifile failed";


print "\n";
print localtime()."\n";
print "$ifile\n";
print "\n";

my $stime = time;
my ($sec, $min, $hour, $d, $m, $y) = localtime(time);
my $today_date= $y*10000 + $m*100 + $d;

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
        my $valid_date = $tmp[$item_loc{'使用期限'}];
        if( $valid_date =~ /\//) {
            my @tmp_date = split /\//, $valid_date;
            next if( $tmp_date[0]*10000 + $tmp_date[1]*100 + $tmp_date[2] < $today_date );
        }

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
    }
}

#單價列放最後才能補小細縫
my @ori_price_tmp = split /,/, $ori_price_line;
for(my $i=$item_1st_loc; $i<@item_name; $i++) {
    $coupon[$coupon_idx][$item_loc{'名稱'}] = $item_name[$i];
    $coupon[$coupon_idx][$item_loc{'優惠代碼'}] = "單點";
    $coupon[$coupon_idx][$item_loc{'連結'}] = "na";
    $coupon[$coupon_idx][$item_loc{'使用期限'}] = "na";
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

#寫下需求清單
foreach my $tmp (keys %req) {
    my $tmp_loc = $item_loc{$tmp};
    die "ERROR! no req $tmp item found!" if( $tmp_loc < $item_1st_loc);
    $reqitem_cur[ $tmp_loc ] = $req{$tmp};
}

print "需求清單:\n";
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

# init log pool
for(my $i=0; $i<$log_capacity+1; $i++) {
    $log_pool[$i] = $ori_price_total;
}

&compute_loop(0);


# sort the cost
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

# print the sorted result
print "\n\n\n";
my $double_cost_bound = $cost_save[$coupon_save_sort[0]]*2;
for(my $i=0; $i<$coupon_save_cnt; $i++) {
    my $i_sort = $coupon_save_sort[$i];
    my $this_cost = $cost_save[$i_sort];
    if($this_cost > $double_cost_bound) {
        print "..bypass the other ".($coupon_save_cnt-$i)." which are more than double of the lowest.\n";
        last;
    }
    if($this_cost > $ori_price_total) {
        print "..bypass the other ".($coupon_save_cnt-$i)." which are more than 單點總價.\n";
        last;
    }
    if( $i>=$log_capacity ) {
        print "..bypass the other ".($coupon_save_cnt-$i)." which are more than log_capacity($log_capacity).\n";
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

print "Runtime: ".($etime-$stime)."s\n";

exit;

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

