# 接口的目的是获得一个 用于 windows 激活的 key，同时提交电脑上的相关的信息给服务器

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

每当客户端需要激活时，就会发送上面的 json 格式的数据，当 keyid 为 0 时，表示请求获得一个 key 用于激活。不为 0 时 ，表示提交使用 key 的结果，同时提交电脑的信息；
如果 keyid 不为 0，且 resultStatus 为 false，表示未成功使用该 key 激活电脑，服务器应该返回另一个 key，以供客户端再次使用。使用后会再次提交信息给服务端。

接口应该返回下面一个数据格式

```
{
	"keyId": 0, # key的唯一标识符  #当keyid 不为0时，表示返回的key是有效的key。为0时只是接受客户端的提交的结果信息。
	"key": "value", # key的值 keyId为0时，key值为空，keyId不为0时，key值为key
}
```

认证机制需要再做讨论

https 状态等字段包在外面，由服务器端定义
