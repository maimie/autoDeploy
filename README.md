"# autoDeploy" 

## 概要
- Virtual Hostを作成
- Virtual Hostにベーシック認証を設定
- ベアリポジトリを作成
- pushにてVirtual Hostに自動反映

## 前提
- CentOS6
- apache
- Virtual Hostとベアリポジトリは同ホスト内
- ドキュメントルートは/home/VIRTUALHOST/public


## ファイル配置
````
private_key
public_key
autoDeployShell.sh
````

## 実行
````
./autoDeployShell.sh VIRTUALHOST PASSWORD HOST PORT
````

## example
````
./autoDeployShell.sh hoge pass 163.163.0.0 22
````

上記を実行すると
````
hoge.mysite.jp
ベーシック認証ID：hoge
ベーシック認証PW：hogepass

IP：163.163.0.0
User：hoge
Port:22

ベアリポジトリ
ssh://remoteRepos/home/repos/VIRTUALHOST/repos.git

````
が作成される


