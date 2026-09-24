/*
 Infomaniak Mail - iOS App
 Copyright (C) 2025 Infomaniak Network SA

 This program is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.

 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 GNU General Public License for more details.

 You should have received a copy of the GNU General Public License
 along with this program. If not, see <http://www.gnu.org/licenses/>.
 */

import Foundation
import MailResources
import RealmSwift

public final class MailTemplate: Object, Codable, ObjectKeyIdentifiable {
    @Persisted(primaryKey: true) public var id: Int
    @Persisted public var title = ""
    @Persisted public var bodyData: Data?
    @Persisted public var attachments: List<Attachment>
    @Persisted public var date = Date()

    public var body: String {
        get {
            guard let decompressedString = bodyData?.decompressedString() else {
                return ""
            }

            return decompressedString
        } set {
            guard let data = newValue.compressed() else {
                bodyData = nil
                return
            }

            bodyData = data
        }
    }

    public var displayName: String {
        title.isEmpty ? MailResourcesStrings.Localizable.unnamedModel : title
    }

    public var inlineImages: [Attachment] {
        attachments.filter { $0.disposition == .inline }
    }

    override public init() {}

    public convenience init(id: Int,
                            title: String,
                            body: String,
                            attachments: [Attachment] = [],
                            date: Date = Date()) {
        self.init()
        self.id = id
        self.title = title
        self.body = body
        self.attachments = attachments.toRealmList()
        self.date = date
    }
}

public extension MailTemplate {
    static let mocks: [MailTemplate] = [
        MailTemplate(
            id: 1,
            title: "Bienvenue chez Infomaniak",
            body: """
            <h1>Bienvenue ! 👋</h1>
            <p>Nous sommes ravis de vous compter parmi nous. Votre compte est désormais actif et vous pouvez accéder à tous nos services.</p>
            <p><strong>Prochaines étapes :</strong></p>
            <ul>
                <li>Configurez votre nom de domaine</li>
                <li>Découvrez kDrive pour stocker vos fichiers</li>
                <li>Personnalisez votre adresse e-mail</li>
            </ul>
            <p>Notre équipe support est disponible 24/7 pour vous accompagner.</p>
            <p style="color: #666; font-size: 12px;">Cordialement, L'équipe Infomaniak</p>
            """
        ),
        MailTemplate(
            id: 2,
            title: "Confirmation de commande",
            body: """
            <h2>Merci pour votre commande</h2>
            <p>Nous avons bien reçu votre commande <strong>#CMD-2026-8472</strong>.</p>
            <table style="width: 100%; border-collapse: collapse;">
                <tr><td style="padding: 8px; border: 1px solid #ddd;">kDrive Pro 1 To</td><td style="padding: 8px; border: 1px solid #ddd;">CHF 10.50/mois</td></tr>
                <tr><td style="padding: 8px; border: 1px solid #ddd;">Nom de domaine .ch</td><td style="padding: 8px; border: 1px solid #ddd;">CHF 15.00/an</td></tr>
            </table>
            <p>Vous recevrez un e-mail séparé lorsque vos services seront activés.</p>
            """
        ),
        MailTemplate(
            id: 3,
            title: "Relance facture impayée",
            body: """
            <p><strong>Objet : Facture #FAC-2026-00342 en attente de paiement</strong></p>
            <p>Bonjour,</p>
            <p>Sauf erreur de notre part, nous n'avons pas encore reçu le règlement de votre facture d'un montant de <strong>CHF 47.90</strong>, arrivée à échéance le <em>15 juillet 2026</em>.</p>
            <div style="background: #fff3cd; padding: 12px; border-left: 4px solid #ffc107; margin: 16px 0;">
                ⚠️ <strong>Rappel :</strong> Vos services pourraient être suspendus sous 7 jours sans régularisation.
            </div>
            <p>Vous pouvez régler en ligne depuis votre <a href="#">espace client</a>.</p>
            <p>En cas de paiement récent, merci de ne pas tenir compte de ce message.</p>
            """
        ),
        MailTemplate(
            id: 4,
            title: "Invitation réunion projet",
            body: """
            <h2>Réunion de lancement — Projet Migration Cloud</h2>
            <p>Bonjour à toutes et à tous,</p>
            <p>Vous êtes convié(e) à la réunion de lancement qui se tiendra le :</p>
            <blockquote>
                📅 <strong>Date :</strong> Mardi 18 août 2026<br>
                🕐 <strong>Heure :</strong> 14h00 - 15h30<br>
                📍 <strong>Lieu :</strong> kMeet (lien envoyé séparément)
            </blockquote>
            <p><strong>Ordre du jour :</strong></p>
            <ol>
                <li>Présentation des objectifs et périmètre</li>
                <li>Architecture technique proposée</li>
                <li>Planning et jalons clés</li>
                <li>Questions diverses</li>
            </ol>
            <p>Merci de confirmer votre présence avant le 14 août.</p>
            """
        ),
        MailTemplate(
            id: 5,
            title: "Réinitialisation du mot de passe",
            body: """
            <p>Vous avez demandé à réinitialiser votre mot de passe.</p>
            <p>Cliquez sur le bouton ci-dessous pour définir un nouveau mot de passe :</p>
            <div style="text-align: center; margin: 24px 0;">
                <a href="#" style="background: #0066cc; color: white; padding: 12px 24px; text-decoration: none; border-radius: 4px; display: inline-block;">Réinitialiser mon mot de passe</a>
            </div>
            <p style="color: #999; font-size: 11px;">Ce lien expire dans 1 heure. Si vous n'avez pas demandé cette réinitialisation, ignorez cet e-mail.</p>
            """
        ),
        MailTemplate(
            id: 6,
            title: "",
            body: """
            <p>Cher client,</p>
            <p>Nous vous informons d'une maintenance planifiée de nos serveurs le <strong>dimanche 23 août 2026 de 2h00 à 4h00</strong>.</p>
            <p>Pendant cette fenêtre, les services suivants pourraient être temporairement indisponibles :</p>
            <ul>
                <li>kDrive</li>
                <li>kMail</li>
                <li>API Public Cloud</li>
            </ul>
            <p>Nous nous excusons pour la gêne occasionnée.</p>
            """
        ),
        MailTemplate(
            id: 7,
            title: "Rapport mensuel d'utilisation",
            body: """
            <h2>📊 Votre consommation de juillet 2026</h2>
            <p>Voici le récapitulatif de votre utilisation :</p>
            <table style="width: 100%; border-collapse: collapse; margin: 16px 0;">
                <tr style="background: #f5f5f5;">
                    <th style="padding: 8px; text-align: left;">Service</th>
                    <th style="padding: 8px;">Utilisé</th>
                    <th style="padding: 8px;">Limite</th>
                </tr>
                <tr>
                    <td style="padding: 8px; border: 1px solid #ddd;">kDrive Stockage</td>
                    <td style="padding: 8px; border: 1px solid #ddd;">742 Go</td>
                    <td style="padding: 8px; border: 1px solid #ddd;">1 To</td>
                </tr>
                <tr>
                    <td style="padding: 8px; border: 1px solid #ddd;">kMail Envoi</td>
                    <td style="padding: 8px; border: 1px solid #ddd;">1 247 emails</td>
                    <td style="padding: 8px; border: 1px solid #ddd;">Illimité</td>
                </tr>
            </table>
            <p><a href="#">Accéder à mon espace client →</a></p>
            """
        ),
        MailTemplate(
            id: 8,
            title: "Pas de body",
            body: """
            """
        ),
        MailTemplate(
            id: 9,
            title: "Vrai mail complet",
            body: """
            <div>
             <br>
            </div>
            <div>
             C’est un test : <b>gras</b>
            </div>
            <div>
             <b><br></b>
            </div>
            <div>
            Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat, sed diam voluptua. At vero eos et accusam et justo duo dolores et ea rebum. Stet clita kasd gubergren, no sea takimata sanctus est Lorem ipsum dolor sit amet. Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat, sed diam voluptua. At vero eos et accusam et justo duo dolores et ea rebum. Stet clita kasd gubergren, no sea takimata sanctus est Lorem ipsum dolor sit amet. Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat, sed diam voluptua. At vero eos et accusam et justo duo dolores et ea rebum. Stet clita kasd gubergren, no sea takimata sanctus est Lorem ipsum dolor sit amet. <b>Duis autem vel eum iriure dolor in hendrerit in vulputate velit esse molestie consequat, vel illum dolore eu feugiat nulla facilisis at vero eros et accumsan et iusto odio dignissim qui blandit praesent luptatum zzril delenit augue duis dolore te feugait nulla facilisi. Lorem ipsum dolor sit amet, consectetuer adipiscing elit, sed diam nonummy nibh euismod tincidunt ut laoreet dolore magna aliquam erat volutpat.  </b> Ut wisi enim ad minim veniam, quis nostrud exerci tation ullamcorper suscipit lobortis nisl ut aliquip ex ea commodo consequat. Duis autem vel eum iriure dolor in hendrerit in vulputate velit esse molestie consequat, vel illum dolore eu feugiat nulla facilisis at vero eros et accumsan et iusto odio dignissim qui blandit praesent luptatum zzril delenit augue duis dolore te feugait nulla facilisi. Nam liber tempor cum soluta nobis eleifend option congue nihil imperdiet doming id quod mazim placerat facer possim assum. Lorem ipsum dolor sit amet, consectetuer adipiscing elit, sed diam nonummy nibh euismod tincidunt ut laoreet dolore magna aliquam erat volutpat. Ut wisi enim ad minim veniam, quis nostrud exerci tation ullamcorper suscipit lobortis nisl ut aliquip ex ea commodo consequat. <i>Duis autem vel eum iriure dolor in hendrerit in vulputate velit esse molestie consequat, vel illum dolore eu feugiat nulla facilisis. </i>At vero eos et accusam et justo duo dolores et ea rebum. Stet clita kasd gubergren, no sea takimata sanctus est Lorem ipsum dolor sit amet. Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat, sed diam voluptua. At vero eos et accusam et justo duo dolores et ea rebum. Stet clita kasd gubergren, no sea takimata sanctus est Lorem ipsum dolor sit amet. Lorem ipsum dolor sit amet, consetetur sadipscing elitr, At accusam aliquyam diam diam dolore dolores duo eirmod eos erat, et nonumy sed tempor et et invidunt justo labore Stet clita ea et gubergren, kasd magna no rebum. sanctus sea sed takimata ut vero voluptua. est Lorem ipsum dolor sit amet. Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat. Consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat, sed diam voluptua. At vero eos et accusam et justo duo dolores et ea rebum. Stet clita kasd gubergren, no sea takimata sanctus est Lorem ipsum dolor sit amet. Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat, sed diam voluptua. At vero eos et accusam et justo duo dolores et ea rebum. Stet clita kasd gubergren, no sea takimata sanctus est Lorem ipsum dolor sit amet. Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat, sed diam voluptua. At vero eos et accusam et justo duo dolores et ea rebum. Stet clita kasd gubergren, no sea takimata sanctus. Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat, sed diam voluptua. At vero eos et accusam et justo duo dolores et ea rebum. Stet clita kasd gubergren, no sea takimata sanctus est Lorem ipsum dolor sit amet. Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat, sed diam voluptua. At vero eos et accusam et justo duo dolores et ea rebum. Stet clita kasd gubergren, no sea takimata sanctus est Lorem ipsum dolor sit amet. Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat, sed diam voluptua. At vero eos et accusam et justo duo dolores et ea rebum. Stet clita kasd gubergren, no sea takimata sanctus est Lorem ipsum dolor sit amet. Duis autem vel eum iriure dolor in hendrerit in vulputate velit esse molestie consequat, vel illum dolore eu feugiat nulla facilisis at vero eros et accumsan et iusto odio dignissim qui blandit praesent luptatum zzril delenit augue duis dolore te feugait nulla facilisi. Lorem ipsum dolor sit amet, consectetuer adipiscing elit, sed diam nonummy nibh euismod tincidunt ut laoreet dolore magna aliquam erat volutpat.Ut wisi enim ad minim veniam, quis nostrud exerci tation ullamcorper suscipit lobortis nisl ut aliquip ex ea commodo consequat. Duis autem vel eum iriure dolor in hendrerit in vulputate velit esse molestie consequat, vel illum dolore eu feugiat nulla facilisis at vero eros et accumsan et iusto odio dignissim qui blandit praesent luptatum zzril delenit augue duis dolore te feugait nulla facilisi.  Nam liber tempor cum soluta nobis eleifend option congue nihil imperdiet doming id quod mazim placerat facer possim assum. Lorem ipsum dolor sit amet, consectetuer adipiscing elit, sed diam nonummy nibh euismod tincidunt ut laoreet dolore magna aliquam erat volutpat. Ut wisi enim ad minim veniam, quis nostrud exerci tation ullamcorper suscipit lobortis nisl ut aliquip ex ea commodo consequat.Duis autem vel eum iriure dolor in
            </div>
            <div>
             <i>&nbsp;Italic. &nbsp;<b>Gras italique&nbsp;</b></i>
            </div>
            <div>
             <i><b><br></b></i>
            </div>
            <div>
             <u>Surligneur&nbsp;</u>
            </div>
            <div>
             <u><br></u>
            </div>
            <div>
             <strike>
              Barre&nbsp;
             </strike>
            </div>
            <div>
             <strike>
              <br>
             </strike>
            </div>
            <div>
             <ul>
              <li>Liste</li>
              <li>Liste2</li>
             </ul>
             <div>
              <a href="https://google.com">Lien</a>
              <br>
             </div>
            </div>
            """
        )
    ]
}
