# Any copyright is dedicated to the Public Domain.
# http://creativecommons.org/publicdomain/zero/1.0/
for i in `seq 130`; do mysql -uroot -p123456 -h192.168.50.94& done; for i in `seq 130`; do mysql -uroot -p123456 -h192.168.50.99& done
