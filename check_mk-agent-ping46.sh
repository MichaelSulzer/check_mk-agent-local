#!/bin/bash
# this script requires bc (sudo apt-get install bc)
#Variables
#Host you would like to ping
host[0]="google.com"
host[1]="ipv6.google.com"
ping[0]="ping"
ping[1]="ping6"

i=0
#how many packets would you like to transmit?
count="10"

#values for warn (warning) and crit (critical)
#warn value for packet loss
plw="30"
#crit value for packet loss
plc="60"
#warn value for average rtt
avgw="500.000"
#crit value for average rtt
avgc="1000.000"

#show debug output
debug="0"

while [ $i -le 1 ]
do
        #Ping the host, only show last 2 lines
        result=$(${ping[$i]} -c ${count} ${host[$i]} | tail -2)
        if [ -z "$result" ];
        then
                echo "3 ${ping[$i]}_${host[$i]} Unable to ${ping[$i]} ${host[$i]}"
                exit 1
        elif [ "$result" != "${result%100% packet loss*}" ];
        then
                echo "2 ${ping[$i]}_${host[$i]} ${ping[$i]}-avg=-1;$avgw;$avgc|${ping[$i]}-mdev=-1|${ping[$i]}-pl=100;$plw;$plc CRIT - ${ping[$i]}-average=-1ms, ${ping[$i]}-mdev=-1ms, ${ping[$i]}-pl=100%"
                exit 1
        else
                #seperate avg ping value
                min=$(echo ${result} | cut -d/ -f4 | cut -d ' ' -f 3)
                #seperate avg ping value
                avg=$(echo ${result} | cut -d/ -f5)
                #seperate max ping value
                max=$(echo ${result} | cut -d/ -f6)
                #seperate mdev ping value
                mdev=$(echo ${result} | cut -d/ -f7 | cut -d ' ' -f 1)
                #seperate packet loss
                pl=$(echo ${result} | cut -d ' ' -f 6 | cut -d% -f 1)

                #debug output
                if [ $debug == "1" ]
                then
                        echo "result is:"
                        echo ${result}
                        echo " "
                        echo "separated values are:"
                        echo "min: ${min}"
                        echo "avg: ${avg}"
                        echo "max: ${max}"
                        echo "mdev: ${mdev}"
                        echo "pl: ${pl}"
                        echo " "
                fi

                #compare values with crit/warn values
                #set default values for status and statustxt
                status=0
                statustxt="OK"

                #compare - warn
                if (( $(bc <<< "$avg > $avgw") ))
                then
                        status=1
                fi
                if (( $(bc <<< "$pl > $plw") ))
                then
                        status=1
                fi

                #compare - crit
                if (( $(bc <<< "$avg > $avgc") ))
                then
                        status=2
                fi
                if (( $(bc <<< "$pl > $plc") ))
                then
                        status=2
                fi

                #set status txt depending on status
                if [ $status == "2" ]
                then
                        statustxt="CRIT"
                fi
                if [ $status == "1" ]
                then
                        statustxt="WARN"
                fi


                #check_mk output
                echo "$status ${ping[$i]}_${host[$i]} ${ping[$i]}-avg=$avg;$avgw;$avgc|${ping[$i]}-mdev=$mdev|${ping[$i]}-pl=$pl;$plw;$plc $statustxt - ${ping[$i]}-average=${avg}ms, ${ping[$i]}-mdev=${mdev}ms, ${ping[$i]}-pl=${pl}%"

        fi
        i=$[$i+1]
done
