## selfhosted-services
The services running on hubbe.club

## Setup
- Create an `.env` file with the ARRAY and MYSQL_ROOT_PASSWORD variables
  - ARRAY - path to storage pool for Videos and other large file content
  - MYSQL_ROOT_PASSWORD - used by `linuxserver/mariadb` container
- Folders for services, probably just restore from borg backup if totally borked
- `docker-compose pull`
- `docker-compose up -d`
