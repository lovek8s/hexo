---
abbrlink: '0'
---
# jenkins devops piplne发送邮件配置


## 准备工作
* 安装email-ext-plugin插件
* 配置jenkins
* pipline发送邮件


## 安装email-ext-plugin插件
jenkins --> 系统管理 --> 系统设置 --> Extended E-mail Notification


## 配置jenkins
Default Subject
```
构建通知:$PROJECT_NAME - Build # $BUILD_NUMBER - $BUILD_STATUS!
```
Default Content
```
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
</head>
<body leftmargin="8" marginwidth="0" topmargin="8" marginheight="4"
    offset="0">
    <table width="95%" cellpadding="0" cellspacing="0"
        style="font-size: 11pt; font-family: Tahoma, Arial, Helvetica, sans-serif">
        <tr>
            <td><br />
            <b><font color="#0B610B">构建信息</font></b>
            <hr size="2" width="100%" align="center" /></td>
        </tr>
        <tr>
            <td>
                <ul> 
                    <li>项目名称：${PROJECT_NAME}</li>
                    <li>构建结果:  <span style="color:red"> ${BUILD_STATUS}</span></li>  
                    <li>构建编号：第${BUILD_NUMBER}次构建 </li>
                    <li>触发原因 ：${CAUSE}</li>
                    <li>GIT 地址： ${gitlabSourceRepoHomepage}</li>                    
                    <li>GIT 分支：${gitlabSourceBranch}</li>
                    <li>镜像标签：${tag}</li>
                    <li>变更记录: ${CHANGES,showPaths=true,showDependencies=true,format="<pre><ul><li>提交ID: %r</li><li>提交人：%a</li><li>提交时间：%d</li><li>提交信息：%m</li><li>提交文件：%p</li></ul></pre>",pathFormat="%p <br />"}
                </ul>
            </td>
        </tr>
        <tr>  
          <td><b><font color="#0B610B">变更集</font></b>  
            <hr size="2" width="100%" align="center" />
          </td>  
        </tr>          
        <tr>  
          <td>${JELLY_SCRIPT,template="html"}<br/>  
            <hr size="2" width="100%" align="center" />
          </td>  
        </tr> 
        <tr>
            <td><b><font color="#0B610B">构建日志 :</font></b>
            <hr size="2" width="100%" align="center" /></td>
        </tr>
        <tr>
            <td><textarea cols="150" rows="30" readonly="readonly"
                    style="font-family: Courier New">${BUILD_LOG}</textarea>
            </td>
        </tr>
    </table>
</body>
</html>
```

## pipline
```
def label = "mypod-${UUID.randomUUID().toString()}"
def tag = '1'
def tomail = 'xxx@xxx.com'
if (gitlabSourceBranch=='T1'){
   tag = 'test'
} else
if (gitlabSourceBranch=='R1'){
    print(gitlabSourceBranch)
} else {
    print("请使用关键分支push触发构建")
    currentBuild.result = 'SUCCESS'
    return
}

podTemplate(label: label,cloud: 'kubernetes',containers: [
    containerTemplate(
        name: 'jnlp',
        alwaysPullImage: true, 
        image: 'registry.cn-hangzhou.aliyuncs.com/mypaas/jenkins-jnlp:latest', 
        privileged: false, 
        ttyEnabled: true, 
        workingDir: '/home/jenkins')
    ], 
    name: "jnlp-${appName}",
    namespace: 'default',  
    podRetention: never(), 
    volumes: [
        hostPathVolume(hostPath: '/var/run/docker.sock', mountPath: '/var/run/docker.sock'), 
        persistentVolumeClaim(claimName: 'jenkins-code-nas', mountPath: '/home/jenkins', readOnly: false)])
{     
    node(label) {
	  try {    
        stage('Clone') {
            echo "1.Clone Stage"
            git credentialsId: 'xxx', url: 'git@xxx.git',branch:gitlabSourceBranch
        }
    
    // get tag
        if (gitlabSourceBranch=='T1'){
           tag = 'test'
        } else
        if (gitlabSourceBranch=='R1'){
            script {
                tag = sh(returnStdout: true, script: 'cat release.tag').trim()
                }
        } 
        print(tag)     
        
		stage('PHPUNIT Test') {
            echo "2.Test Stage"
            sh 'printenv'
        }
        // mail stage
        emailext ( 
            body: '''
            ${DEFAULT_CONTENT}
            ''', 
            recipientProviders: [developers()], 
            subject: '${DEFAULT_SUBJECT}', 
            to: "${tomail}"
            )         
      } catch (any) {
        currentBuild.result = 'FAILURE'
        throw any
    } finally {
        if (currentBuild.result == 'FAILURE') {  
          emailext ( 
            body: '''
            ${DEFAULT_CONTENT}
            ''', 
            recipientProviders: [developers()], 
            subject: '${DEFAULT_SUBJECT}', 
            to: "${tomail}"
            )
        }      
      }        
    }    
}        
```

## 参考文档

* [https://github.com/jenkinsci/email-ext-plugin/tree/master/src/main/resources/hudson/plugins/emailext/templates](https://github.com/jenkinsci/email-ext-plugin/tree/master/src/main/resources/hudson/plugins/emailext/templates)

* [https://github.com/whihail/AutoArchive/wiki/%E5%AE%A2%E6%88%B7%E7%AB%AFJenkins%E8%87%AA%E5%8A%A8%E6%9E%84%E5%BB%BA%E6%8C%87%E5%8D%97%E4%B9%8B%E9%82%AE%E4%BB%B6%E9%80%9A%E7%9F%A5](https://github.com/whihail/AutoArchive/wiki/%E5%AE%A2%E6%88%B7%E7%AB%AFJenkins%E8%87%AA%E5%8A%A8%E6%9E%84%E5%BB%BA%E6%8C%87%E5%8D%97%E4%B9%8B%E9%82%AE%E4%BB%B6%E9%80%9A%E7%9F%A5)