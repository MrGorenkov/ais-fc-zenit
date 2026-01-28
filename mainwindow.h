#ifndef MAINWINDOW_H
#define MAINWINDOW_H

#include <QMainWindow>
#include <QSqlDatabase>

QT_BEGIN_NAMESPACE
namespace Ui { class MainWindow; }
QT_END_NAMESPACE

class MainWindow : public QMainWindow
{
    Q_OBJECT

public:
    MainWindow(QWidget *parent = nullptr);
    ~MainWindow();

private:
    QSqlDatabase dbconn;
    Ui::MainWindow *ui;

public slots:
    void dbconnect();
    void selectAll();
    void add();
    void del();
    void edit();
};
#endif // MAINWINDOW_H
















