# Serviço "web" do Railway: constrói o app direto do repositório (sem limite de 96 KB das Functions).
FROM oven/bun:1.2.19-alpine
WORKDIR /srv
COPY src/app.ts ./app.ts
ENV NODE_ENV=production
# sem root: a imagem oficial já traz o usuário "bun"
USER bun
EXPOSE 3000
CMD ["bun", "app.ts"]
