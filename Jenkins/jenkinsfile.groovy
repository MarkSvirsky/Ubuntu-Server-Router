pipeline {
    agent any

    stages {
        stage('Checkout Testing') {
            steps {
                checkout scmGit(
                    branches: [[name: '*/testing']], 
                    userRemoteConfigs: [[
                        credentialsId: 'git-token', 
                        url: 'https://github.com/MarkSvirsky/Ubuntu-Server-Router.git'
                    ]]
                )
            }
        }

        stage('Validate Netplan & DNS') {
            steps {
                script {
                    echo "📦 Preparing Virtual Twin for validation..."
                    sh "docker run -d --name dns-test ubuntu:24.04 sleep 300"
                    try {
                        sh "docker cp configs dns-test:/tmp/configs"
                        sh """
                            docker exec -e DEBIAN_FRONTEND=noninteractive dns-test sh -c "
                                apt-get update && apt-get install -y netplan.io dnsmasq --no-install-recommends &&
                                mkdir -p /etc/netplan &&
                                cp /tmp/configs/netplan/*.yaml /etc/netplan/ &&
                                netplan generate && 
                                dnsmasq --test --conf-file=/tmp/configs/dnsmasq/server-gateway.conf
                            "
                        """
                    } finally {
                        sh "docker rm -f dns-test"
                    }
                }
            }
        }

        stage('IPTables Lockout Test') {
            steps {
                script {
                    echo "🛡️ Simulating Firewall & Testing SSH Accessibility..."
                    sh "docker run --privileged -d --name net-check ubuntu:24.04 sleep 300"
                    try {
                        sh "docker cp configs net-check:/tmp/configs"
                        sh """
                            docker exec -e DEBIAN_FRONTEND=noninteractive net-check sh -c "
                                apt-get update && apt-get install -y iptables --no-install-recommends &&
                                iptables-restore < /tmp/configs/routing/iptables.sh
                            "
                        """
                        // ✅ FIXED REGEX ORDER: Looking for ACCEPT then Port 22
                        if (sh(script: "docker exec net-check iptables -L INPUT -n | grep -q 'ACCEPT.*dpt:22'", returnStatus: true) == 0) {
                            echo '✅ SSH Port 22 is confirmed open.'
                        } else {
                            error("❌ CRITICAL: This config would LOCK YOU OUT of SSH. Build failed.")
                        }
                    } finally {
                        sh "docker rm -f net-check"
                    }
                }
            }
        }

         stage('Promote to Main') {
    steps {
        echo '✅ All tests passed! Promoting Testing -> Main...'
        withCredentials([usernamePassword(credentialsId: 'git-token', passwordVariable: 'GIT_TOKEN', usernameVariable: 'GIT_USER')]) {
            // Standard config can stay in double quotes
            sh 'git config user.email "jenkins@junker-gateway"'
            sh 'git config user.name "Jenkins CI"'
            
            // ✅ USE SINGLE QUOTES HERE
            // This prevents Groovy from touching the variables. 
            // The Linux Shell handles the expansion securely.
            sh 'git push https://${GIT_USER}:${GIT_TOKEN}@github.com/MarkSvirsky/Ubuntu-Server-Router.git HEAD:main'
        }
    }
}               }
            }
        }
    }
}
