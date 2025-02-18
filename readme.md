# PostgreSQL Docker 镜像构建指南

本 Dockerfile 用于构建一个包含 Apache AGE、PGvector、PGAudit 和 pgsodium 扩展的 PostgreSQL 镜像。镜像基于 `postgres:16`（Debian Bookworm）构建，支持多种扩展功能，适用于需要图数据库、向量搜索、审计和加密功能的场景。

## 关键要点

1. **基础镜像**：基于 `postgres:16` 镜像，使用 Debian Bookworm 作为操作系统。
2. **扩展支持**：
   - **Apache AGE**：支持图数据库功能，版本为 `PG16/v1.5.0-rc0`。
   - **PGvector**：支持向量搜索，版本为 `0.8.0`。
   - **PGAudit**：提供审计功能，版本为 `REL_16_STABLE`。
   - **pgsodium**：提供加密功能，版本为 `3.1.9`。
   - **pgvecto.rs**：支持向量搜索，版本为 `0.4.0`。
   - **pgvectorscale**：支持向量缩放，版本为 `0.5.1`。
3. **构建阶段**：
   - **Builder 阶段**：用于编译和安装所有扩展。
   - **Final 阶段**：基于 `postgres:16` 镜像，将编译好的扩展复制到最终镜像中。
4. **依赖安装**：在构建阶段安装了必要的构建工具和依赖项，如 `postgresql-server-dev-16`、`build-essential`、`libsodium-dev` 等。
5. **扩展安装**：通过 Git 克隆和编译的方式安装所有扩展，并将生成的 `.so` 文件和扩展脚本复制到 PostgreSQL 的扩展目录中。
6. **健康检查**：使用 `pg_isready` 命令进行健康检查，确保 PostgreSQL 服务正常运行。
7. **端口暴露**：默认暴露 PostgreSQL 的 5432 端口。
8. **启动命令**：启动 PostgreSQL 时预加载 `age`、`vector`、`vectors` 和 `pgaudit` 扩展。

## 使用方法

1. **构建镜像**：
   ```bash
   docker build -t mypg:16 .
   ```

```md readme.md (续)
2. **运行容器**：
   ```bash
   docker run -d --name mypg -e POSTGRES_PASSWORD=mypassword -p 5432:5432 mypg:16   
   ```
   这将启动一个 PostgreSQL 容器，并将主机的 5432 端口映射到容器的 5432 端口。

3. **初始化数据库**：
   在容器启动时，`init.sql` 脚本会自动执行，用于初始化数据库。你可以在 `init.sql` 中定义所需的数据库、用户、权限和扩展的启用。

4. **自定义配置**：
   `custom.conf` 文件包含了自定义的 PostgreSQL 配置。你可以根据需要修改此文件，以调整 PostgreSQL 的行为。{可在`Dockerfile`中修改`CMD` 启动命令中的`-c`选项来加载自定义配置。}
5. **健康检查**：
   容器内置了健康检查功能，每隔 30 秒检查一次 PostgreSQL 是否正常运行。如果服务不可用，容器将自动重启。

6. **日志查看**：
   你可以通过以下命令查看容器的日志：
   ```bash
   docker logs mypg
   ```

7. **进入容器**：
   如果需要进入容器进行调试或管理，可以使用以下命令：
   ```bash
   docker exec -it mypg bash
   ```

## 扩展功能说明

### Apache AGE
Apache AGE 是一个基于 PostgreSQL 的图数据库扩展，支持图数据的存储和查询。它允许你在 PostgreSQL 中使用 Cypher 查询语言进行图数据操作。

### PGvector
PGvector 是一个用于向量搜索的 PostgreSQL 扩展，支持高效的向量相似度搜索。它适用于机器学习模型生成的向量数据的存储和检索。

### PGAudit
PGAudit 是一个审计扩展，用于记录 PostgreSQL 数据库的所有操作。它可以帮助你监控和审计数据库的使用情况，确保数据的安全性。

### pgsodium
pgsodium 是一个加密扩展，提供了多种加密功能，包括对称加密、非对称加密和哈希函数。它可以帮助你保护敏感数据的安全。

### pgvecto.rs
pgvecto.rs 是一个高性能的向量搜索扩展，基于 Rust 实现。它提供了比 PGvector 更高的性能和更丰富的功能。

### pgvectorscale
pgvectorscale 是一个用于向量缩放的扩展，支持对大规模向量数据进行高效的缩放和索引。它适用于需要处理大规模向量数据的场景。

## 注意事项

1. **版本兼容性**：确保所有扩展的版本与 PostgreSQL 的版本兼容。当前 Dockerfile 中使用的扩展版本均支持 PostgreSQL 16。
2. **安全性**：在生产环境中使用 pgsodium 时，请确保密钥文件的安全存储和管理。
<!-- 3. **性能调优**：根据实际需求调整 `custom.conf` 中的配置参数，以优化 PostgreSQL 的性能。 -->

## 常见问题

### 如何更新扩展版本？
你可以通过修改 Dockerfile 中的 `AGE_VERSION`、`PGVECTOR_VERSION` 等变量来更新扩展的版本。然后重新构建镜像即可。

### 如何添加新的扩展？
在 Builder 阶段，按照现有扩展的安装方式，添加新的扩展的编译和安装步骤。然后将生成的 `.so` 文件和扩展脚本复制到 `/usr/local/lib/postgresql/` 和 `/usr/local/share/postgresql/extension/` 目录中。

### 如何调试扩展加载问题？
如果扩展加载失败，可以进入容器查看 PostgreSQL 的日志文件，通常位于 `/var/log/postgresql/postgresql-16-main.log`。日志中会记录扩展加载失败的原因。

## 贡献指南
欢迎提交 Issue 和 Pull Request 来改进此项目。请在提交前确保代码风格一致，并通过所有测试。

## 许可证
本项目采用 MIT 许可证。详细信息请参阅 [LICENSE](LICENSE) 文件。

## 参考文档
- [Apache AGE 官方文档](https://age.apache.org/)
- [PGvector 官方文档](https://github.com/pgvector/pgvector)
- [PGAudit 官方文档](https://github.com/pgaudit/pgaudit)
- [pgsodium 官方文档](https://github.com/michelp/pgsodium)
- [pgvecto.rs 官方文档](https://github.com/tensorchord/pgvecto.rs)
- [pgvectorscale 官方文档](https://github.com/timescale/pgvectorscale)
```
