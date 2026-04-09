# CICD
개발자가 작성한 코드를 서비스 환경에 안전하고 빠르게 반영하기 위한 파이프라인 구축. 단순 자동 배포에서 서버가 스스로 상태를 관리하고 문제 발생 시 즉각 대응할 수 있는 시스템.
---------------------------------------------------------------------------------

1.무중단 자동 배포
  deploy.sh을 통해 ArgoCD를 거쳐 코드가 승인되면 자동으로 서버에 반영
2.순서 제어
  AI 파트의 마이그레이션이 완료된 후 백엔드가 가동되도록 배포 순서 조정
3.self heal 시스템
  pod이 죽거나 에러가 뜨면 시스템이 이를 감지해 정상 상태로 복구될때까지 재실행
  
---------------------------------------------------------------------------------
backend/, ai/, frontend/:	서비스별 매니페스트	
  deployment.yaml: 실제로 서비스에서 어떻게 돌아갈지 정의
    리소스, probe, 환경변수 주입, 모니터링 연결 등
  service.yaml: deploy pod를 실제 서비스로 연결시키는 역할
    정적 주소 부여, 로드밸런싱, 포트 연결

자동화
deploy.sh: 통합 배포 역할
	AWS 동적 주소를 자동으로 매니페스트에 주입, Git에 push
applications.yaml: GitOps 동기화 설정
  ArgoCD application 정의서
setup-secrets.sh: 쿠버네티스 보안정보 생성
  
terraform 부팅 후 kubectl apply -f applications.yaml > ./deploy.sh
pod 재배포시 ./deploy.sh
