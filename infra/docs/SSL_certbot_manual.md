# 1. DNS 설정 확인
	1.	도메인 scspace.kws.sparcs.net이 해당 서버의 공인 IP로 제대로 연결되어 있어야 합니다.
	2.	**80번 포트(HTTP)**가 서버 방화벽이나 클라우드 보안 설정에서 열려 있어야 Certbot이 도메인 검증(http-01) 과정을 진행할 수 있습니다.
	•	HTTPS(443)도 마찬가지로 열려 있어야 최종적으로 인증서 적용 후 접근이 가능합니다.

	Tip: ping scspace.kws.sparcs.net 했을 때, 해당 서버 IP가 뜨면 DNS 연결이 정상이라고 볼 수 있습니다.

# 2. Certbot 설치

우분투에서 certbot을 설치하는 가장 흔한 방법은 snap을 통해서 설치하는 것입니다.
(기존 apt-get 방식도 있지만, 최신 우분투라면 snap이 권장)

A) snapd가 설치되어 있는지 확인

```bash
sudo apt-get update
sudo apt-get install snapd
```

B) snapd 최신 버전으로 갱신

```bash
sudo snap install core
sudo snap refresh core
```

C) certbot 설치

```bash
sudo snap install --classic certbot
```

D) 이제 certbot 명령을 전역에서 쓸 수 있도록 링크를 만듭니다:

```bash
sudo ln -s /snap/bin/certbot /usr/bin/certbot
```

# 3. 인증서 발급

```bash
sudo certbot --nginx -d scspace.kws.sparcs.net
```
```
scspace@scspace-prod:~/scspace$ sudo certbot --nginx -d scspace.kws.sparcs.net
Saving debug log to /var/log/letsencrypt/letsencrypt.log
Enter email address (used for urgent renewal and security notices)
 (Enter 'c' to cancel): scspace.kaist@gmail.com

- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
Please read the Terms of Service at
https://letsencrypt.org/documents/LE-SA-v1.5-February-24-2025.pdf. You must
agree in order to register with the ACME server. Do you agree?
```

•	--nginx: Nginx 설정을 자동으로 수정해 주는 플러그인 사용
	•	-d scspace.kws.sparcs.net: 인증서를 발급받을 도메인(또는 서브도메인) 지정
	•	여러 도메인(예: -d scspace.kws.sparcs.net -d www.scspace.kws.sparcs.net)도 가능

Certbot이 다음 과정을 진행합니다:
	1.	HTTP-01 챌린지: Nginx 설정에 임시 location을 추가하여 Let’s Encrypt가 http://scspace.kws.sparcs.net/.well-known/acme-challenge/...로 접근해 서버 소유권을 검증
	2.	검증 성공 시 인증서 발급
	3.	인증서와 키 파일을 /etc/letsencrypt/live/scspace.kws.sparcs.net/ 아래에 저장
	4.	Nginx SSL 설정 자동 업데이트 (질문에 따라 “HTTP->HTTPS 리다이렉트” 적용할지 물어볼 수도 있음)

마지막에 성공 메시지가 뜨면, “Nginx가 443 포트”로 SSL이 적용된 상태가 됩니다.

# 4. 인증서 자동 갱신 확인

Let’s Encrypt 인증서는 유효기간 90일입니다. 보통 자동 갱신을 위해 /etc/cron.d/certbot 또는 systemd timer가 설정됩니다.

확인:

```bash
sudo certbot renew --dry-run
```
	•	만약 --dry-run 테스트가 성공하면, 실제 만료 시점에 자동으로 갱신이 됩니다.
	•	sudo certbot renew를 수동 실행해도 되고, cron이나 systemd 서비스가 일정 주기로 갱신 시도합니다.
# 5. 인증서 적용 확인


