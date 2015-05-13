class Format

  SimplePhoneFormat : (phone) ->
    return null if not phone

    number = null
    if phone.length >= 10
      number =
      "(" + phone[0 .. 2] + ") " +
      phone[3 .. 5] + "-" +
      phone[6 .. 9]

      if phone.length > 10
        number += " " + phone[10 .. phone.length]
    else if phone.length is 7
      number =
        "" + phone[0 .. 2] + '-' + phone[3 .. 6]

    return number