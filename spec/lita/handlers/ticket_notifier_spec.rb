require "spec_helper"
require "json"

describe Lita::Handlers::TicketNotifier, lita_handler: true do
  let(:payload) { File.read(File.join('spec', 'fixtures', 'ticket.json')) }
  let(:request) { OpenStruct.new({ body: OpenStruct.new({ read: payload }) }) }
  let(:teddy) { Lita::User.create(123, name: "Teddy Ruxbin") }
  let(:batman) { Lita::User.create(567, name: "The Batman") }
  let(:ticket_messsage) { "Ticket: test ticket\nState:review\nImportance:Low\nTags:dev\nhttp://waffles.lighthouseapp.com/projects/1/tickets/200" }

  it { routes_command("ticket notify start").to(:add_ticket_notification) }
  it { routes_command("ticket notify stop").to(:remove_ticket_notification) }
  it { routes_http(:post, "/ticket_notification").to(:ticket_notification) }

  it "notifies correct users about tickets" do
    expect(subject).to receive(:send_message_to_user).with(user.name, ticket_messsage)
    expect(subject).to receive(:send_message_to_user).with(teddy.name, ticket_messsage)
    expect(subject).to_not receive(:send_message_to_user).with(batman.name, ticket_messsage)

    send_command("ticket notify start")
    send_command("ticket notify start", as: teddy)
    send_command("ticket notify start", as: batman)
    send_command("ticket notify stop", as: batman)

    subject.ticket_notification(request, nil)
  end

  it "doesn't add you twice" do
    send_command("ticket notify start")
    send_command("ticket notify start")

    expect(replies.count).to eq(2)
    expect(replies.first).to eq("You will now get notified of ticket updates.")
    expect(replies.last).to eq("You're already on the list.")

    expect(subject).to receive(:send_message_to_user).once

    subject.ticket_notification(request, nil)
  end

  it "lets you know you're already not getting notifications" do
    send_command("ticket notify stop")

    expect(replies.count).to eq(1)
    expect(replies.first).to eq("You weren't on the list.")
  end

  it "doesn't send notifications to nobody" do
    expect(subject).to_not receive(:send_message_to_user)
    subject.ticket_notification(request, nil)
  end
end
