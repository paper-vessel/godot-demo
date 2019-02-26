extends FirebaseAuth

const GOOGLE_PROVIDER_ID = "google.com"
const FACEBOOK_PROVIDER_ID = "facebook.com"

func _ready():
	# initialize with config. note that this options file ignored on mobiles.
	var f = File.new()
	f.open("res://google-services.json", File.READ)
	initialize(f.get_as_text())
	f.close()

	# setting up demo UI button
	$Sign/SignInButton.add_item("Choose Sign In method")
	$Sign/SignInButton.add_icon_item(preload("res://google_icon.png"), "Google Sign In")
	$Sign/SignInButton.add_icon_item(preload("res://facebook_icon.png"), "Facebook Sign In")
	$Sign/SignInButton.add_icon_item(preload("res://icon.png"), "Custom token Sign In")
	$Sign/SignInButton.add_icon_item(preload("res://firebase_icon.png"), "Anonymous Sign In")

	connect("on_auth_state_changed", self, "auth_state_listner")
	connect("on_id_token_changed", self, "id_token_listner")

	$Sign/SignInButton.connect("item_selected", self, "sign_in")
	$Sign/SignOutButton.connect("button_up", self, "sign_out")
	$Link/GoogleButton.connect("button_up", self, "link_account", [GOOGLE_PROVIDER_ID])
	$Link/FacebookButton.connect("button_up", self, "link_account", [FACEBOOK_PROVIDER_ID])

	invalidate()

func message(message):
	$AcceptDialog/CenterContainer/Label.text = message
	$AcceptDialog/CenterContainer/Label.visible = true
	$AcceptDialog/CenterContainer/LineEdit.visible = false
	$AcceptDialog.popup_centered()

func auth_state_listner(sign_in):
	invalidate()

func id_token_listner():
	retrieve_token(false)
	var res = yield(self, "on_retrieve_token_complete")
	print("firebase token: ", res.token)
	if res.auth_error != kAuthErrorNone:
		message(res.error_message)

func invalidate():
	var has_user = has_user()
	$Sign/SignInButton.visible = not has_user
	$Sign/SignOutButton.visible = has_user
	$Link.visible = has_user
	if has_user:
		var providers = get_provider_ids()
		var google_linked = providers.has(GOOGLE_PROVIDER_ID)
		$Link/GoogleButton.disabled = google_linked
		$Link/GoogleButton.text = "LINKED" if google_linked else "LINK"
		var facebook_linked = providers.has(FACEBOOK_PROVIDER_ID)
		$Link/FacebookButton.disabled = facebook_linked
		$Link/FacebookButton.text = "LINKED" if facebook_linked else "LINK"

func sign_in(id):
	print($Sign/SignInButton.get_item_text(id))
	match id:
		1:
			request_google_id_token()
			var res = yield(self, "on_request_google_id_token_complete")
			if res.auth_error != kAuthErrorNone:
				message(res.error_message)
				return
			sign_in_with_google_id_token(res.google_id_token)
			res = yield(self, "on_sign_in_complete")
			if res.auth_error != kAuthErrorNone:
				message(res.error_message)
		2:
			request_facebook_access_token()
			var res = yield(self, "on_request_facebook_access_token_complete")
			if res.auth_error != kAuthErrorNone:
				message(res.error_message)
				return
			sign_in_with_facebook_access_token(res.access_token)
			if res.auth_error != kAuthErrorNone:
				message(res.error_message)
		3:
			$AcceptDialog/CenterContainer/LineEdit.visible = true
			$AcceptDialog/CenterContainer/Label.visible = false
			$AcceptDialog.popup_centered()
			yield($AcceptDialog, "hide")
			sign_in_with_custom_token($AcceptDialog/CenterContainer/LineEdit.text)
		4:
			sign_in_anonymously()

func link_account(idp):
	match idp:
		"google.com":
			request_google_id_token()
			var res = yield(self, "on_request_google_id_token_complete")
			if res.auth_error != kAuthErrorNone:
				message(res.error_message)
				return
			link_with_google_id_token(res.google_id_token)
		"facebook.com":
			request_facebook_access_token()
			var res = yield(self, "on_request_facebook_access_token_complete")
			if res.auth_error != kAuthErrorNone:
				message(res.error_message)
				return
			link_with_facebook_access_token(res.access_token)
	var res = yield(self, "on_link_complete")
	if res.auth_error != kAuthErrorNone:
		message(res.error_message)
