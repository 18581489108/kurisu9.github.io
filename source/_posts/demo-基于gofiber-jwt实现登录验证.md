---
title: 'demo: 基于gofiber + jwt实现登录验证'
tags:
  - demo
  - golang
  - gofiber
  - jwt
date: 2021-07-02 10:38:04
---

# 前言
在分布式项目中，传统的session进行用户的登录验证已经力不从心，使用token代替seesion也逐渐成为了一种趋势。最近在拿gofiber写demo中时，为了后续再扩展为分布式应用，于是结合jwt实现了一套简单的登录验证系统。

在实现鉴权系统中，需要解决的问题:
* 密码泄漏
* 生成jwt的secret泄漏
* 修改密码后，使旧的jwt失效

# 设计思路
## 注册
![注册流程](https://gitee.com/makise.kurisu/filestorage/raw/master/images/blog/demo-%E5%9F%BA%E4%BA%8Egofiber-jwt%E5%AE%9E%E7%8E%B0%E7%99%BB%E5%BD%95%E9%AA%8C%E8%AF%81/%E6%B3%A8%E5%86%8C%E6%B5%81%E7%A8%8B.png)

1. 通过username + 随机字符串生成唯一的salt。
2. 在保存密码时，不能保存明文密码，通常需要保存密码的摘要。通过前一步生成的salt，来提高密码的安全性。
3. 最后将username、salt、hash过的密码写入数据库

## 登录
![登录流程](https://gitee.com/makise.kurisu/filestorage/raw/master/images/blog/demo-%E5%9F%BA%E4%BA%8Egofiber-jwt%E5%AE%9E%E7%8E%B0%E7%99%BB%E5%BD%95%E9%AA%8C%E8%AF%81/%E7%99%BB%E5%BD%95%E6%B5%81%E7%A8%8B.png)

1. 通过username读取出数据库中的用户信息
2. 通过存储的salt和用户输入的密码，进行hash
3. 比较hash过的密码与数据库中存储的密码是否一致

## 生成token
![生成token流程](https://gitee.com/makise.kurisu/filestorage/raw/master/images/blog/demo-%E5%9F%BA%E4%BA%8Egofiber-jwt%E5%AE%9E%E7%8E%B0%E7%99%BB%E5%BD%95%E9%AA%8C%E8%AF%81/token%E7%94%9F%E6%88%90%E6%B5%81%E7%A8%8B.png)

1. 通过存储的salt、登录时间戳生成jwt的salt，并存入redis
2. 将jwt salt与私有密钥进行hash，生成jwt secret
3. 将一些用户信息（例如用户id、username等非敏感信息）写入claims
4. 通过claims、jwt secret生成token

## 验证token
![token验证流程](https://gitee.com/makise.kurisu/filestorage/raw/master/images/blog/demo-%E5%9F%BA%E4%BA%8Egofiber-jwt%E5%AE%9E%E7%8E%B0%E7%99%BB%E5%BD%95%E9%AA%8C%E8%AF%81/token%E9%AA%8C%E8%AF%81%E6%B5%81%E7%A8%8B.png)

1. 从http header中的```Authorization```字段中读取到token
2. 从token解析出用户相关信息，包括username
3. 根据username从redis中获取到jwt salt
4. 再将jwt salt与私有密钥进行hash，生成jwt secret
5. 验证token是否合法

# 实现方案
## 项目结构
整体项目结构如下: 
```bash
├── README.md      
├── cmd
│   └── authjwtdemo
│       └── Main.go
├── configs        
│   └── app.yaml   
├── go.mod
├── go.sum
└── internal       
    ├── app        
    │   └── authjwtdemo
    │       ├── auth_jwt_demo.go
    │       ├── config
    │       │   └── config.go
    │       ├── def
    │       │   └── rediskey
    │       │       └── redis_key.go
    │       ├── handler
    │       │   ├── api.go
    │       │   ├── auth.go
    │       │   ├── base_handler.go
    │       │   └── product.go
    │       ├── middleware
    │       │   ├── auth.go
    │       │   └── auth_test.go
    │       ├── model
    │       │   ├── init_model.go
    │       │   ├── product.go
    │       │   └── user_base.go
    │       └── router
    │           └── router.go
    └── pkg
        ├── database
        │   └── connect.go
        ├── random
        │   └── randstr
        │       └── randstr.go
        ├── redis
        │   ├── go_redis_template.go
        │   ├── go_redis_template_test.go
        │   └── redis_template.go
        └── timeutil
            └── timeutil.go
```

项目结构参考了[golang-standards/project-layout](https://github.com/golang-standards/project-layout)。

完整源码见[kurisu9az/jwt-auth-demo](https://github.com/kurisu9az/jwt-auth-demo)

实现了注册、登录、token验证、登出等逻辑。

## 注册
注册时，需要处理由前端传递的username和password，这里不考虑前端传递password是否要进行加密。
### 基础流程
```golang
// internal/app/authjwtdemo/handler/auth.go

type RegisterInput struct {
	UserName string `json:"username" validate:"required,min=3,max=20"`
	Password string `json:"password" validate:"required,min=3,max=20"`
}

func Register(ctx *fiber.Ctx) error {
	var input RegisterInput
	if err := bodyParserAndValidate(&input, ctx); err != nil {
		return err
	}

	username := input.UserName
	password := input.Password

	userBase := new(model.UserBase)
	userBase.Username = username

	// 生成salt
	salt, err := generateSalt(username)
	if err != nil {
		return InternalServerError(ctx, "Couldn't generate salt", err)
	}
	userBase.Salt = salt

	// 对密码进行hash
	hashedPassword, err := hashPassword(password, userBase.Salt)
	if err != nil {
		return InternalServerError(ctx, "Couldn't hash password", err)
	}
	userBase.Password = hashedPassword

	db := database.DB
	if err := db.Create(&userBase).Error; err != nil {
		return InternalServerError(ctx, "Couldn't create user", err)
	}

	return SuccessError(ctx, "Register Success", input)
}
```

上述流程中，比较核心的地方在于salt的生成以及对密码的hash。

### 生成slat
```golang
// internal/app/authjwtdemo/handler/auth.go

func generateSalt(username string) (string, error) {
	// TODO 随机字符串的长度可以考虑读取配置
	str := randstr.RandomAscii(20)

	bytes, err := bcrypt.GenerateFromPassword([]byte(username+"."+str), 14)
	return string(bytes), err
}
```

1. 将username和随机生成的20位字符串进行拼接，这样可以保证每个用户的salt是唯一的。
2. 最后使用bcrypt进行hash处理。

注: bcrypt.GenerateFromPassword方法本身也会再加一次salt，所以在生成salt时要不要先加salt就需要自己衡量了。

### 对密码进行hash
```golang
// internal/app/authjwtdemo/handler/auth.go

func addSaltToPassword(password string, salt string) string {
	return password + "." + salt
}

func hashPassword(password string, salt string) (string, error) {
	bytes, err := bcrypt.GenerateFromPassword([]byte(addSaltToPassword(password, salt)), 14)
	return string(bytes), err
}
```

1. 将前面生成的salt与原始密码进行拼接。
2. 再使用bcrypt进行hash处理。

## 登录
登录时同样需要处理由前端传递的username和password，这里不考虑前端传递password是否要进行加密。
### 基础流程
```golang
// internal/app/authjwtdemo/handler/auth.go

type LoginInput struct {
	UserName string `json:"username" validate:"required,min=3,max=20"`
	Password string `json:"password" validate:"required,min=3,max=20"`
}

func Login(ctx *fiber.Ctx) error {
	var input LoginInput
	if err := bodyParserAndValidate(&input, ctx); err != nil {
		return err
	}

	username := input.UserName
	password := input.Password

	userBase, err := getUserByUsername(username)
	if err != nil {
		return UnauthorizedError(ctx, "Error on username", err)
	}

	if userBase == nil {
		return UnauthorizedError(ctx, "User not found", username)
	}

	if !checkPasswordHash(userBase, password) {
		return UnauthorizedError(ctx, "Invalid password", nil)
	}

	jwtSalt := middleware.GenerateJwtSecretSalt(userBase.Salt)
	secret := middleware.GenerateJwtSecret(jwtSalt)
	if secret == "" {
		return UnauthorizedError(ctx, "Generate secret failed", nil)
	}

	t, err := middleware.GenerateJwtToken(userBase, secret, config.Config.JwtConfig.TokenExpiration)
	if err != nil {
		log.Println(err)
		return ctx.SendStatus(fiber.StatusInternalServerError)
	}

	// 写入redis
	// 进行过时的处理
	redis.Template.SetEX(rediskey.FormatJwtSaltRedisKey(userBase.ID), jwtSalt, config.Config.JwtConfig.TokenSaltExpiration)
	return SuccessError(ctx, "Success login", middleware.JWTAuthScheme+" "+t)
}
```
登录中比较核心逻辑在于比对用户输入的密码和数据库中的密码是否一致。在登录成功以后，需要为用户生成token。

在生成token以后，需要在redis中缓存生成token的jwt salt。

### 检查密码是否一致
```golang
// internal/app/authjwtdemo/handler/auth.go

func checkPasswordHash(userBase *model.UserBase, originPassword string) bool {
	// CompareHashAndPassword这方法是真滴慢，估计得考虑降低cost
	err := bcrypt.CompareHashAndPassword([]byte(userBase.Password), []byte(addSaltToPassword(originPassword, userBase.Salt)))
	return err == nil
}
```

1. 对输入的密码进行同样的加盐处理。
2. 使用bcrypt.CompareHashAndPassword比较数据中的密码，与输入的密码是否一致。

### 生成jwt secret
```golang
// internal/app/authjwtdemo/middleware/auth.go

// 生成用于jwt的密匙 salt
func GenerateJwtSecretSalt(userSalt string) string {
	return fmt.Sprintf("%s.%d", userSalt, timeutil.CurrentTimeMillis())
}

// 生成jwt的密钥
func GenerateJwtSecret(salt string) string {
	staticSecret := config.Config.JwtConfig.PrivateSecret
	return fmt.Sprintf("%x", md5.Sum([]byte(salt+"."+staticSecret)))
}
```

1. 根据用户的salt以及登录时间戳生成jwt的salt。
2. 将jwt salt与配置文件中的private secret进行拼接后，使用md5处理，得到最终的jwt secret。

### 生成JWT
```golang
// internal/app/authjwtdemo/middleware/auth.go

// 生成jwt token
func GenerateJwtToken(userBase *model.UserBase, secret string, expiration time.Duration) (string, error) {
	claims := UserClaims{
		UserSimpleInfo{
			Username: userBase.Username,
			UserId:   userBase.ID,
		},
		jwt.StandardClaims{
			ExpiresAt: timeutil.NextTimeSeconds(expiration),
			Issuer:    config.Config.JwtConfig.Issuer,
		},
	}

	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	return token.SignedString([]byte(secret))
}
```

1. 将基本的、非敏感的用户数据写入到claims中，以及token的过期时间等信息。
2. 最后使用前面的jwt secret生成JWT。

注: JWT中通常建议存储一些非敏感的数据，如果需要存储敏感数据，那么一定要做好加密措施。同时不要在JWT中存储过多、过长的数据，否则在每次请求中都是一个很大的开销，且有些浏览器会对过长的JWT进行截断操作。

## 验证token
在某些请求中，需要保证用户登录以后再能访问，所以需要对token进行验证。

```golang
func JWTAuthMiddleware() fiber.Handler {
	return func(c *fiber.Ctx) error {
		auth, err := jwtFromHeader(c, fiber.HeaderAuthorization, JWTAuthScheme)
		if err != nil {
			c.Status(fiber.StatusBadRequest)
			return c.JSON(fiber.Map{"status": "error", "message": "Missing or malformed JWT", "data": nil})
		}

		token, err := jwt.ParseWithClaims(auth, &UserClaims{}, func(t *jwt.Token) (interface{}, error) {
			userClaims, ok := t.Claims.(*UserClaims)
			if !ok {
				return nil, errors.New("not support Claims")
			}

			userId := userClaims.UserInfo.UserId
			if userId <= 0 {
				return nil, errors.New("invalid user id ")
			}

			salt := redis.Template.Get(rediskey.FormatJwtSaltRedisKey(userId))
			if salt == "" {
				return nil, errors.New("not found salt")
			}

			secret := GenerateJwtSecret(salt)
			if secret == "" {
				return nil, errors.New("secret generate failed")
			}
			return []byte(secret), nil
		})

		if err == nil && token.Valid {
			// Store user information from token into context.
			userClaims := token.Claims.(*UserClaims)
			c.Locals(UserInfoKey, &userClaims.UserInfo)
			return c.Next()
		}

		c.Status(fiber.StatusUnauthorized)
		return c.JSON(fiber.Map{"status": "error", "message": "Invalid or expired JWT", "data": nil})
	}
}
```

1. 从header中读取到token
2. 根据token拿到用户id，并且从redis中获取jwt salt
3. 通过jwt salt与private secret来生成jwt secret并校验token

## 登出
登出后，需要保证旧的token失效。如果只是根据JWT的过期时间来限制，那么玩家登出以后JWT不会立即失效。因此通过移除redis中的jwt salt即可以保证JWT立即过期。
```golang
func Logout(ctx *fiber.Ctx) error {
	userInfo := ctx.Locals(middleware.UserInfoKey).(*middleware.UserSimpleInfo)
	redis.Template.Del(rediskey.FormatJwtSaltRedisKey(userInfo.UserId))
	return SuccessError(ctx, "Logout success", userInfo.UserId)
}
```

# 结束
回到开始提出的三个问题，

### 如何解决密码泄漏
通过对原始密码进行加盐处理后，在数据库中只存储被hash过的密码，即使数据库泄漏，也没法反推出用户的原始密码。

### 如何防止生成jwt的secret泄漏
1. 没有直接存储jwt secret，因此不存在直接泄漏的问题。
2. 生成jwt secret时，依赖了用户salt、登录时间戳，以及配置文件中的private secret。只要private secret没有泄漏，就算是知道了jwt secret的生成算法，也无法伪造出合法的jwt。
3. 将jwt salt缓存在redis中，可以提高token验证的效率。

### 如何在修改密码后，使旧的jwt失效
修改密码后，通常需要伴随重新登录，所以只需要在修改完密码以后，移除掉redis中的jwt salt即可。在重新登录以后，会生成新的jwt salt，所以旧的jwt是会验证失败。

# 参考
* [Web App Token 鉴权方案的设计与思考](https://zhuanlan.zhihu.com/p/28295641)
* [go-fiber](https://github.com/gofiber/fiber)
* [jwt-go](https://pkg.go.dev/github.com/form3tech-oss/jwt-go@v3.2.3+incompatible?utm_source=gopls#section-readme)
* [auth-jwt](https://github.com/gofiber/recipes/tree/master/auth-jwt)
* [JWT validation with JWKS golang](https://stackoverflow.com/questions/61850992/jwt-validation-with-jwks-golang)
* [golang-standards/project-layout](https://github.com/golang-standards/project-layout)