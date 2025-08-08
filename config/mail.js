import { Resend } from "resend";
import CodeVerificationEmail from "../templates/mail-template.jsx";

const resend = new Resend(process.env.RESEND);

const sendEmail = async (to, subject, username, code) => {
    try {
        const response = await resend.emails.send({
            from: process.env.SENDER_MAIL,
            to: to,
            subject: `${subject}-(no-reply)`,
            react: CodeVerificationEmail({ username, code })
        });
        return response;
    } catch (error) {
        console.error(error);
        throw error;
    }
}
export default sendEmail;













