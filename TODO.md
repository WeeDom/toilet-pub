# Guard-e-loo — Development Roadmap

## EPICS

### Epic 1: 🔧 Infrastructure Enhancement
**Goal**: Complete the production-ready infrastructure foundation
**Status**: 🟡 **PARTIALLY COMPLETE** - WordPress dual-stack operational, ESP32 baseline deployed
**Stories**:
- **Story 1.1**: ✅ **COMPLETE** - Docker-based WordPress dual-stack (production/staging/proxy)
- **Story 1.2**: ✅ **COMPLETE** - SSL automation & deployment scripts (`manage.sh`, migration tools)
- **Story 1.3**: ✅ **COMPLETE** - ESP32 firmware baseline (v0.1.0 deployed, camera operational)
- **Story 1.4**: ❌ **TODO** - Ansible playbooks for automated server provisioning
- **Story 1.5**: ❌ **TODO** - Remote Firmware Update Infrastructure
  - EC2 as CNC (Command & Control)
  - SSH tunnel: EC2 → Pi Gateway
  - Pi-based OTA server (HTTP for ESP32s)
  - Ansible orchestration for multi-site deployments
- **Story 1.6**: ❌ **TODO** - Test Lab Setup (2 laptops, 1 camera, simulated site)
- **Story 1.7**: ❌ **TODO** - OpenProject Installation & Integration
  - Docker-based OpenProject on same server
  - HTTPS access via `projects.guard-e-loo.co.uk`
  - Integrated with nginx proxy and `manage.sh`
  - PostgreSQL database with automated backups

### Epic 2: 🎯 Smart Privacy Detection
**Goal**: Implement PIR-based occupancy detection to disable cameras when toilets are in use
**Status**: 🟡 **READY TO START** - Much simpler and safer than image-based motion detection
**Stories**:
- **Story 2.1**: PIR WiFi Sensor Nodes (ESP8266 + PIR, battery-powered, £5 per unit)
- **Story 2.2**: Camera Disable/Enable API (Pi controls all ESP32-CAMs via HTTP)
- **Story 2.3**: Occupancy Timer System (auto re-enable cameras after timeout)
- **Story 2.4**: Multi-Sensor Coverage (multiple PIR nodes per facility)

### Epic 3: 🌐 Device Communication Layer
**Goal**: Enable ESP32 devices to communicate with Pi controllers
**Status**: ❌ **NOT STARTED** - Current web interface is manual
**Stories**:
- **Story 3.1**: ESP32 API Enhancement (motion endpoints, device registration)
- **Story 3.2**: ESP32 ↔ Pi Communication (HTTP client, motion event reporting)
- **Story 3.3**: Device Status & Heartbeat Protocol
- **Story 3.4**: Image Upload & Metadata Protocol

### Epic 4: 💾 Edge Controller (Raspberry Pi)
**Goal**: Build Pi-based local controller for camera management
**Status**: 🟡 **BASIC PROTOTYPE** - Motion detection working with tablet cam
**Stories**:
- **Story 4.1**: ✅ **BASIC COMPLETE** - Local motion detection (`pi1/main.py`)
- **Story 4.2**: ESP32-CAM Integration (replace tablet cam with ESP32 devices)
- **Story 4.3**: Multi-Camera Management & Store-Forward

### Epic 5: ☁️ Central Management Platform
**Goal**: Create cloud-based monitoring and control system
**Status**: 🟡 **INFRASTRUCTURE READY** - WordPress platform operational
**Stories**:
- **Story 5.1**: Central API Server (Django/FastAPI endpoints)
- **Story 5.2**: Site & Device Management Dashboard
- **Story 5.3**: Real-time Monitoring & Alerts

### Epic 6: 🔒 Security & Production Readiness
**Goal**: Implement security measures and reliability features
**Status**: 🟡 **BASIC COMPLETE** - SSL/HTTPS operational
**Stories**:
- **Story 6.1**: ✅ **COMPLETE** - HTTPS/SSL & secure WordPress setup
- **Story 6.2**: ❌ **HIGH PRIORITY** - Police Public Key Encryption (RSA/ECC for police-only decryption)
- **Story 6.3**: ❌ **HIGH PRIORITY** - Dynamic Key Management (Go server, daily refresh, caching)
- **Story 6.4**: ❌ **HIGH PRIORITY** - Emergency Key Revocation System (push refresh, <60s response)
- **Story 6.5**: ESP32 ↔ Pi Authentication (pre-shared keys/tokens)
- **Story 6.6**: Over-the-Air Updates & Remote Management

### Epic 7: 🧪 System Validation
**Goal**: Test and validate system performance and reliability
**Status**: ❌ **NOT STARTED**
**Stories**:
- **Story 7.1**: Performance Benchmarking (motion detection FPS, power usage)
- **Story 7.2**: Multi-Device Field Testing
- **Story 7.3**: Production Deployment Validation

---

## RELEASE MILESTONES

| Version | Epic Focus | Key Deliverable | Status |
|---------|------------|----------------|---------|
| **v0.1.0** | Epic 1 | ✅ WordPress platform operational | **COMPLETE** |
| **v0.2.0** | Epic 2 | Motion detection on ESP32-CAM | **NEXT** |
| **v0.3.0** | Epic 3 + 4 | Pi ↔ ESP32 integration working | Planned |
| **v0.4.0** | Epic 5 | Central dashboard operational | Planned |
| **v1.0.0** | Epic 6 + 7 | Production-ready system | Target |

---

## IMMEDIATE NEXT ACTIONS

### Priority 1: Complete Foundation (Epic 1)
- Add Ansible playbooks for server provisioning automation
- Create ESP32 firmware build/deployment pipeline
- Tag current ESP32 code as `v0.1.0` baseline

### Priority 2: Begin Motion Detection (Epic 2)
- Implement performance optimizations in ESP32 camera code
- Add motion detection algorithm with configurable thresholds
- Test dual-stage capture (fast detection → high-res image)

---

*Last updated: November 2025*
