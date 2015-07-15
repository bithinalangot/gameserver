all:

backup:
	mysqldump -u root --opt --add-drop-database -a -B ctf > backup.`date +%s`.sql

empty.db.sql:
	./clean_db.sh
	mysqldump -u root -a -B ctf > empty.db.sql

gameserver:
	scp * gameserver:~

drone:
	scp config DOCUMENTATION common.pm control.pl drone.pl monitor.pl mysql.pm drone1:~

tar: 
	rm -f gameserver.tgz
	tar cvzf gameserver.tgz -T publish.this.files --no-same-owner 

#publish: tar
#	cp gameserver.tgz /mnt/auto/homepage/public_html/download
