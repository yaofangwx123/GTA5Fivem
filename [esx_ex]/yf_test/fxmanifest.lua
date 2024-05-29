fx_version 'bodacious'
game 'gta5'

author 'xptech'
version '1.0.0'


client_script {
'@es_extended/locale.lua',
'locales/*.lua',
'config.lua',
'client.lua',
}

server_script {

'@oxmysql/lib/MySQL.lua',
'@es_extended/locale.lua',
'locales/*.lua',
'config.lua',
'server.lua'

}

shared_script '@es_extended/imports.lua'

dependencies {
	'es_extended'
}

