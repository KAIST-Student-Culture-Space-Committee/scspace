-- 데이터베이스 및 사용자 권한 설정

GRANT ALL PRIVILEGES ON scspace.* TO 'scspace'@'%';
GRANT PROCESS, RELOAD, LOCK TABLES, REPLICATION CLIENT ON *.* TO 'scspace'@'%';

-- DataGrip에서 덤프 및 업로드 허용
GRANT FILE ON *.* TO 'scspace'@'%';
GRANT SELECT, INSERT, UPDATE, DELETE, CREATE, DROP, INDEX, ALTER, SHOW VIEW, CREATE TEMPORARY TABLES ON scspace.* TO 'scspace'@'%';
FLUSH PRIVILEGES;
