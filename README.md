# CICD
개발자가 작성한 코드를 서비스 환경에 안전하고 빠르게 반영하기 위한 파이프라인 구축. 단순 자동 배포에서 서버가 스스로 상태를 관리하고 문제 발생 시 즉각 대응할 수 있는 시스템.
---------------------------------------------------------------------------------
핵심 구축 내용
1. Reusable Workflow 기반의 중앙 집중식 CI 설계

    중앙 관리 체계: AI, Backend, Frontend 각 서비스 레포지토리에 파편화된 빌드 로직을 cicd 레포지토리의 action-deploy.yml로 단일화하여 유지보수 효율을 극대화했습니다.

    Self-hosted Runner 운용: 보안 강화 및 비용 절감을 위해 로컬 가상머신 기반 Runner를 구축, AWS 자격 증명 및 kubectl 인증 컨텍스트를 안전한 환경에서 관리합니다.

2. InitContainer를 활용한 스마트 배포 순서 제어 (Dependency Control)

    문제 해결: AI 서비스의 DB 마이그레이션(Alembic)이 완료되기 전 백엔드가 기동되어 발생하는 런타임 접속 에러를 원천 차단했습니다.

    지능형 기동 로직: 백엔드 Pod에 InitContainer를 설계하여, AI 서비스의 헬스체크 포트(8000)가 활성화될 때까지 백엔드 기동을 자동 대기시키는 인과 관계 배포를 구현했습니다.

3. ArgoCD 기반 GitOps 및 자가 치유(Self-Healing) 시스템

    선언적 인프라 관리: Git 저장소의 매니페스트와 클러스터 상태를 실시간 동기화하여 인프라의 형상을 코드로 관리(IaC)합니다.

    Self-Healing: 클러스터 설정이 Git 정의에서 벗어나거나 수동 변조될 경우, 시스템이 이를 즉각 감지하고 1분 이내에 정상 상태로 자동 복구합니다.

    동적 엔드포인트 주입: deploy.sh를 통해 Terraform으로 생성된 RDS, ElastiCache 등의 동적 엔드포인트를 실시간 조회하여 매니페스트에 자동 반영하는 프로세스를 구축했습니다.


Deployment Flow

인프라 프로비저닝: Terraform을 통해 EKS 및 관리형 서비스 생성

GitOps 등록: kubectl apply -f applications.yaml (ArgoCD 서비스 등록)

통합 배포 실행: ./deploy.sh 실행 시 동적 환경변수 주입 및 Git Push -> ArgoCD 자동 배포 트리거
