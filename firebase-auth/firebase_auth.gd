extends FirebaseAuth

func _ready():
	$Sign/SignInButton.add_item("Choose Sign In method")
	$Sign/SignInButton.add_icon_item(preload("res://google_icon.png"), "Google Sign In")
	$Sign/SignInButton.add_icon_item(preload("res://facebook_icon.png"), "Facebook Sign In")
	$Sign/SignInButton.add_icon_item(preload("res://icon.png"), "Custom token Sign In")
	$Sign/SignInButton.add_icon_item(preload("res://firebase_icon.png"), "Anonymous Sign In")

	var f = File.new()
	f.open("res://google-services.json", File.READ)
	initialize(f.get_as_text())
	f.close()
	
	connect("on_auth_state_changed", self, "auth_state_listner")
	connect("on_id_token_changed", self, "id_token_lestner")

	$Sign/SignInButton.connect("item_selected", self, "sign_in")
	$Sign/SignOutButton.connect("button_up", self, "sign_out")
	$Link/GoogleButton.connect("button_up", self, "link_account", ["google.com"])
	$Link/FacebookButton.connect("button_up", self, "link_account", [])

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
	var message = res.token if res.auth_error == kAuthErrorNone else res.error_message
	message(message)

func invalidate():
	var has_user = has_user()
	$Sign/SignInButton.visible = not has_user
	$Sign/SignOutButton.visible = has_user
	$Link.visible = has_user
	if has_user:
		var providers = get_provider_ids()
		var google_linked = providers.has("google.com")
		$Link/GoogleButton.disabled = google_linked
		$Link/GoogleButton.text = "LINKED" if google_linked else "LINK"
		var facebook_linked = providers.has("")
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
		2:
			pass
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