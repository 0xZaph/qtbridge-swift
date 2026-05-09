import QtQuick
import QtQuick.Controls as Controls
import org.kde.kirigami as Kirigami

Kirigami.ApplicationWindow {
    id: root
    width: 600
    height: 400
    visible: true
    title: "Kirigami Demo"

    // The Sidebar
    globalDrawer: Kirigami.GlobalDrawer {
        title: "Navigation"
        titleIcon: "view-list-icons"
        
        actions: [
            Kirigami.Action {
                text: "Home"
                icon.name: "go-home"
                onTriggered: pageStack.replace(homePage)
            },
            Kirigami.Action {
                text: "About"
                icon.name: "help-about"
                onTriggered: pageStack.replace(aboutPage)
            }
        ]
    }

    // Page 1: Home
    Component {
        id: homePage
        Kirigami.Page {
            title: "Home"
            
            Controls.Label {
                anchors.centerIn: parent
                text: "Welcome to the Home Page"
                font.pointSize: 20
            }
        }
    }

    // Page 2: About
    Component {
        id: aboutPage
        Kirigami.Page {
            title: "About"
            
            Controls.Label {
                anchors.centerIn: parent
                text: "This is a simple 2-page template."
            }
        }
    }

    // Default startup page
    pageStack.initialPage: homePage
}