"# autoDeploy" 

## �T�v
- Virtual Host���쐬
- Virtual Host�Ƀx�[�V�b�N�F�؂�ݒ�
- �x�A���|�W�g�����쐬
- push�ɂ�Virtual Host�Ɏ������f

## �O��
- CentOS6
- apache
- Virtual Host�ƃx�A���|�W�g���͓��z�X�g��
- �h�L�������g���[�g��/home/VIRTUALHOST/public


## �t�@�C���z�u
````
private_key
public_key
autoDeployShell.sh
````

## ���s
````
./autoDeployShell.sh VIRTUALHOST PASSWORD HOST PORT
````

## example
````
./autoDeployShell.sh hoge pass 163.163.0.0 22
````

��L�����s�����
````
hoge.mysite.jp
�x�[�V�b�N�F��ID�Fhoge
�x�[�V�b�N�F��PW�Fhogepass

IP�F163.163.0.0
User�Fhoge
Port:22

�x�A���|�W�g��
ssh://remoteRepos/home/repos/VIRTUALHOST/repos.git

````
���쐬�����


