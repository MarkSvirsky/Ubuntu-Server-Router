pipeline {
    agent any

    stages {
        stage('Checkout Testing') {
            steps {
                // Jenkins pulls the latest from your 'testing' branch
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
                    // Start a background container to act as the 'Twin'
                    sh "docker run -d --name dns-test ubuntu:24.04 sleep 300"
                    
                    try {
                        // Copy configs from the Jenkins workspace into the container
                        sh "docker cp configs dns-test:/tmp/configs"
                        
                        // Run the validation inside the Ubuntu environment
                        sh """
                            docker exec -e DEBIAN_FRONTEND=noninteractive dns-test sh -c "
                                apt-get update && apt-get install -y netplan.io dnsmasq --no-install-recommends &&
                                mkdir -p /etc/netplan &&
                                cp /tmp/configs/netplan/*.yaml /etc/netplan/ &&
                                echo 'Checking Netplan Syntax...' &&
                                netplan generate && 
                                echo 'Checking Dnsmasq Syntax...' &&
                                dnsmasq --test --conf-file=/tmp/configs/dnsmasq/server-gateway.conf
                            "
                        """
                        echo "✅ Netplan and DNS Validation Passed."
                    } finally {
                        // Always clean up the container
                        sh "docker rm -f dns-test"
                    }
                }
            }
        }

        stage('IPTables Lockout Test') {
            steps {
                script {
                    echo "🛡️ Simulating Firewall & Testing SSH Accessibility..."
                    // Start a privileged container for real iptables testing
                    sh "docker run --privileged -d --name net-check ubuntu:24.04 sleep 300"
                    
                    try {
                        sh "docker cp configs net-check:/tmp/configs"
                        
                        sh """
                            docker exec -e DEBIAN_FRONTEND=noninteractive net-check sh -c "
                                apt-get update && apt-get install -y iptables --no-install-recommends &&
                                iptables-restore < /tmp/configs/routing/iptables.sh &&
                                echo 'Firewall loaded. Checking SSH port...'
                            "
                        """
                        
                        // This grep looks for your EXPLICIT SSH rule. 
                        // If it's missing, the build fails to prevent a lockout.
			if (sh(script: "docker exec net-check iptables -L INPUT -n | grep -q 'ACCEPT.*dpt:22'", returnStatus: true) == 0)
*raw
:PREROUTING ACCEPT [0:0]
:OUTPUT ACCEPT [0:0]
-A PREROUTING -d 172.18.0.2/32 ! -i br-c10e951d4035 -j DROP
COMMIT

*filter
:INPUT ACCEPT [0:0]
:FORWARD ACCEPT [0:0]
:OUTPUT ACCEPT [0:0]

# 1. Allow established connections (Crucial for stability)
-A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

# 2. THE RULE JENKINS IS LOOKING FOR
-A INPUT -p tcp --dport 22 -j ACCEPT

# 3. Allow Jenkins UI
-A INPUT -p tcp --dport 8080 -j ACCEPT

# ... the rest of your rules ...

*nat
:PREROUTING ACCEPT [0:0]
:INPUT ACCEPT [0:0]
:OUTPUT ACCEPT [0:0]
:POSTROUTING ACCEPT [0:0]
-A POSTROUTING -o enp5s0 -j MASQUERADE
COMMIT
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
                    sh """
                        git config user.email "jenkins@junker-gateway"
                        git config user.name "Jenkins CI"
                        git push https://${GIT_USER}:${GIT_TOKEN}@github.com/MarkSvirsky/Ubuntu-Server-Router.git HEAD:main
                    """
                }
            }
        }
    }
    
    post {
        always {
            echo "Pipeline Finished. Status: ${currentBuild.result}"
        }
        failure {
            echo "🛑 BUILD FAILED: One of your configs is dangerous or broken."
        }
    }
}
