def dockerBuildPush(imageName,commitId,ENV){
		sh "export AWS_PROFILE=dev-eks-cluster"
		sh "docker build -t ${imageName}:${commitId} ."
		sh "docker tag ${imageName}:${commitId} 198145494826.dkr.ecr.ap-south-1.amazonaws.com/${imageName}:${commitId}"
		sh "docker tag ${imageName}:${commitId} 198145494826.dkr.ecr.ap-south-1.amazonaws.com/${imageName}:${ENV}"
		sh "aws ecr get-login-password --region ap-south-1 | docker login --username AWS --password-stdin 198145494826.dkr.ecr.ap-south-1.amazonaws.com"
		sh "docker push 198145494826.dkr.ecr.ap-south-1.amazonaws.com/${imageName}:${commitId}"
		sh "docker push 198145494826.dkr.ecr.ap-south-1.amazonaws.com/${imageName}:${ENV}"
		sh "docker rmi 198145494826.dkr.ecr.ap-south-1.amazonaws.com/${imageName}:${commitId}"
		sh "docker rmi 198145494826.dkr.ecr.ap-south-1.amazonaws.com/${imageName}:${ENV}"
		sh "docker rmi ${imageName}:${commitId} "
}

def deploymentK8s(commitId,deploymentName,imageName,clusterName,ENV){
	withAWS(profile:'dev-eks-cluster') {
		withKubeConfig([credentialsId: "${clusterName}" ]) {
			sh "export AWS_PROFILE=dev-eks-cluster"
			sh "cat k8s/${ENV}_deployment.yaml | sed -e  's+{{IMAGE_NAME}}+${imageName}+g' -e  's+{{ENV}}+${ENV}+g' -e 's+{{REPLACE_IT}}+${env.BUILD_NUMBER}+g' | kubectl apply -f -"
			// sh "kubectl annotate deployment ${deploymentName} kubernetes.io/change-cause='${commitId}' --record=false --overwrite=true"
			// sh "kubectl apply -f k8s/${ENV}/service.yaml"
		}
	}
}

def sendSlackNotification(serviceName,commitId,dev_name){
		def attachments = [
	[
		text: "Build Successful for Service '$serviceName', Build Number: ${env.BUILD_NUMBER} and commit ID: '${commitId}', pushed by ${dev_name}",
	//	fallback: 'Hey, ',
		color: '#00FF00'
	]
	]

	slackSend(channel: "#release", attachments: attachments)
}

def sendJiraNotification(stage,commitId){
	def jiraServer = 'webapp'
	def testIssue = [fields: [ 
		project: [id: '10089'],
		summary: "Build Failed at stage '${STAGE}', for Build Number: ${env.BUILD_NUMBER} and commit ID: '${commitId}' ",
		description: "",
		issuetype: [name: 'Story'],
		]]

	response = jiraNewIssue issue: testIssue, site: jiraServer
	echo response.successful.toString()
	echo response.data.toString()
}

node {
    def commitId 
	def dev_email

    stage('SCM') {
		cleanWs()
        checkout scm 
        sh 'git rev-parse --short HEAD > .git/commit-id'
        commitId = readFile('.git/commit-id').trim()
		dev_email = sh(script: "git --no-pager show -s --format='%ae'", returnStdout: true).trim()
		dev_name = sh(script: "git --no-pager show -s --format='%an'", returnStdout: true).trim()	
		sh "echo ${dev_name}"	
        }

	def imageName = "v1"
    def clusterName = "dev-eks-cluster"       

	if (env.BRANCH_NAME.equals("release-2.0.4")){

		def deploymentName = "webapp-v1"
		def environment = "dev"
	    def serviceName = "webapp v1 dev" 

		try{	
			stage('Docker Build/Push Cleanup') {
                STAGE=env.STAGE_NAME
				//dockerBuildPush("${imageName}","${commitId}","${environment}")
			}

		//	stage('Deployment') {
      //          STAGE=env.STAGE_NAME
	//			deploymentK8s("${commitId}", "${deploymentName}", "${imageName}", "${clusterName}","${environment}")	
//			}

			stage('Success'){
				//sendSlackNotification("${serviceName}","${commitId}","${dev_name}")
			}} catch(error){
				stage('Failure'){
					//sendJiraNotification("${STAGE}","${commitId}")
				}
			}	 
		
	}
	else if (env.BRANCH_NAME.equals("qa-k8s")){

		def deploymentName = "webapp-v1"
		def environment = "qa"
		def serviceName = "webapp v1 qa"

		try{	
			stage('Docker Build/Push Cleanup') {
                STAGE=env.STAGE_NAME
				dockerBuildPush("${imageName}","${commitId}","${environment}")
			}

			stage('Deployment') {
                STAGE=env.STAGE_NAME
				deploymentK8s("${commitId}", "${deploymentName}", "${imageName}", "${clusterName}","${environment}")	
			}

			stage('Success'){
				sendSlackNotification("${serviceName}","${commitId}","${dev_name}")
			}} catch(error){
				stage('Failure'){
					sendJiraNotification("${STAGE}","${commitId}")
				}
			}	 
		
	}
}
