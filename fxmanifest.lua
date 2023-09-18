fx_version 'adamant'

game 'gta5'

description 'MasterkinG32 Custom codes'

version '1.0.0'

client_scripts {
	'client/*.lua'
}

server_scripts {
	'server/main.lua',
	'config.lua'
}

dependency 'es_extended'

ui_page 'ui/index.html'
files {
  'ui/index.html',
  'ui/style.css',
  'ui/animate.min.css',
  'ui/img/logo.png',
  'ui/persian-date.min.js',
}