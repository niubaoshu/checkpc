# 获得 key 的接口

```
{
    "username": "moumou",  # 用户名,或者是操作员
    "password": "password", # 密码 暂定，取决于认证方式,某些认证方式可能不需要username和password个字段
    "sn": "a234354564234", # 电脑的序列号  理论上电脑型号和电脑序列号组合唯一确定一台电脑
    "model": "N151", # 电脑的型号
    "osVersion": "mircosoft window 11 home", # 操作系统版本 ，如果此字段包含home，则应该返回hom ekey；如果此字段包含pro，则应该返回pro key
}
```

该接口总是返回下面这样一个数据格式

```
{
    "keyId": 3259666517449, # key 的唯一标识符
    "key": "W7PY2-N837X-89C72-4PPXP-D69QR" # key
}

```

# key 使用情况的报告接口

1. 使用 key 失败时报告的信息

```
{
    "username": "moumou",  # 用户名,或者是操作员
    "password": "password", # 密码 暂定，取决于认证方式,某些认证方式可能不需要username和password个字段
    "keyId": 0,   # key的唯一标识符
    "sn": "a234354564234", # 电脑的序列号  理论上电脑型号和电脑序列号组合唯一确定一台电脑
    "model": "N151", # 电脑的型号
    "osVersion": "mircosoft window 11 home", # 操作系统版本 ，如果此字段包含home，则应该返回homekey；如果此字段包含pro，则应该返回pro key
    "resultStatus": false, # 激活结果
    "resultMessage": "value", # 激活结果信息，由微软返回，不做修改存到服务器端
}
```

服务器收到这个信息后应该再次返回一个 key

```
{
    "keyId": 3259666517449, # key 的唯一标识符
    "key": "W7PY2-N837X-89C72-4PPXP-D69QR" # key
}

```

2. 成功使用 key 时报告的信息

```
{
    "username": "moumou",  # 用户名,或者是操作员
    "password": "password", # 密码 暂定，取决于认证方式,某些认证方式可能不需要username和password个字段
    "keyId": 0,   # key的唯一标识符
    "sn": "a234354564234", # 电脑的序列号  理论上电脑型号和电脑序列号组合唯一确定一台电脑
    "model": "N151", # 电脑的型号
    "osVersion": "mircosoft window 11 home", # 操作系统版本 ，如果此字段包含home，则应该返回homekey；如果此字段包含pro，则应该返回pro key
    "resultStatus": true, # 激活结果
    "resultMessage": "value", # 激活结果信息，由微软返回，不做修改存到服务器端
    "cpu": "amd 6600h",  # CPU 型号
    "memory": [   # 安装的内存列表
        {
            "id": 0,  # 内存插槽的id
            "size": 1024, # 内存的大小 单位是byte
            "speed": "value", # 内存的速度
            "manufacturer": "value" # 内存的制造商
        }
    ],
    "disk": [  # 安装的硬盘列表
        {
            "id": 0, # 硬盘id 本机的第几个硬盘
            "size": 1024,  # 硬盘的大小  单位是byte
            "interfaceType": "SCSI", # 硬盘的接口类型
            "model": "NVMe KINGSTON SNV2S1000G", #  硬盘的型号
        }
    ]
}

```

认证机制需要再做讨论

https 状态等字段包在外面，由服务器端定义
